note
	description: "Mass testing of Xpact parsing of XML files against eXpat"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-18 14:00:00 GMT (Saturday 18th July 2026)"
	revision: "1"

class
	FILE_TREE_TESTS

inherit
	PARSE_EVENT_CONSTANTS

	XT_PARSE_CONSTANTS
		export
			{NONE} all
		end

	XT_STRING_ROUTINES_I

	XT_SHARED_EXECUTION_ENVIRONMENT

create
	make

feature {NONE} -- Initialization

	make (a_dir_path: PATH)
		require
			latin_1_path: a_dir_path.name.is_valid_as_string_8
		do
			create expat_error.make_empty
			if attached a_dir_path.entry as entry and then attached entry.name as last_step
				and then last_step.starts_with ("*.")
			then
				wild_card := last_step.to_string_8
				dir_path := a_dir_path.parent
			else
				wild_card := Default_wild_card
				dir_path := a_dir_path
			end
			make_log
			create file.make_with_path (log.path)
		end

	make_log
		do
			create log.make_with_path (new_log_path)
		end

feature -- Access

	fail_count: INTEGER

	pass_count: INTEGER

feature -- Basic operations

	execute
		do
			make_log_directory
			if attached new_find_results as find_results and then find_results.has_output then
				do_tests (find_results)
				put_results (False, pass_count, fail_count)
			end
			if not logs_retained and then attached Environment as env then
				env.remove_directory (env.temporary_path (env.command_name), True)
			end
		end

feature -- Status change

	keep_logs
		do
			logs_retained := True
		end

feature -- Status report

	logs_retained: BOOLEAN

feature {NONE} -- Implementation

	call_expat_xml_crc_32 (type: STRING; file_path: PATH)
		-- call C program xml_crc_32 setting `expat_return_code' and `expat_checksum'
		local
			output_file: XT_COMMAND_OUTPUT_FILE; done: BOOLEAN
			index: INTEGER
		do
			expat_checksum := 0
			create output_file.make_with_output (Xml_crc_32, << type, file_path >>)
			expat_return_code := output_file.return_code
			if expat_return_code > 0 then
				expat_error := output_file.error_lines.first
				if output_file.has_output then
					output_file.delete
				end

			elseif output_file.has_output then
				from until done loop
					output_file.read_line
					if output_file.end_of_file then
						done := True
					elseif attached output_file.last_string as line and then line.starts_with (once "Checksum") then
						index := line.index_of (':', 1)
						expat_checksum := line.substring (index + 2, line.count).to_natural
						done := True
					end
				end
				output_file.close
			end
		end

	data_type_pass_count (file_path: PATH): INTEGER
		-- count of data types that pass checksum comparison with eXpat
		-- -1 if both Xpact and eXpat fail to parse invalid document
		local
			values_differ, both_fail: BOOLEAN; crc_32: CRC_32_GENERATOR
			description: STRING
		do
			across Parse_data_types as data_type until values_differ or both_fail loop
				create crc_32.make (data_type)
				crc_32.parse_file (file_path, 0, True)
				call_expat_xml_crc_32 (@ data_type.key, file_path)
				if crc_32.status /= Status_ok and expat_return_code > 0 then
					both_fail := True
					Result := -1

				elseif crc_32.status = Status_ok then
					if crc_32.checksum.value = expat_checksum then
						Result := Result + 1
					else
						put_log_values_differ (file_path)
						log.put_string (
							substitute (Checksum_comparison, << @ data_type.key, crc_32.checksum.value.out, expat_checksum.out >>)
						)
						log.put_new_line; log.put_new_line
						values_differ := True
					end
				else
					if crc_32.status = Status_error then
						description := crc_32.error_description
					else
						description := crc_32.status_description
					end
					log.put_string (substitute (Error_template, << description, file_path.out >>))
					log.put_new_line; log.put_new_line
					values_differ := True
				end
			end
		end

	do_tests (find_results: XT_COMMAND_OUTPUT_FILE)
		local
			done: BOOLEAN; i, count: INTEGER
		do
			log.open_write
			pass_count := 0; fail_count := 0
			from until done loop
				find_results.read_line
				if find_results.end_of_file then
					done := True
				else
					i := i + 1
					IO.put_integer (i); IO.put_string (". ")
					if attached find_results.last_path as file_path then
						if attached file_path.name as name then
							if name.has (' ') then
								IO.put_character ('"')
							end
							IO.put_string_32 (name)
							if name.has (' ') then
								IO.put_character ('"')
							end
						end
						if has_content (file_path) then
							count := data_type_pass_count (file_path)
							if count = -1 or count = Parse_data_types.count then
								IO.put_string (" OK")
								if count = -1 then
									IO.put_string (" (Both failed)")
									IO.put_new_line
									IO.put_string ("   "); IO.put_string (expat_error)
								end
								pass_count := pass_count + 1
							else
								IO.put_string (" FAILED")
								fail_count := fail_count + 1
							end
						else
							IO.put_string (" EMPTY skipped")
						end
						IO.put_new_line
					end
				end
			end
			find_results.close
			log.close
			if log.count = 0 then
				log.delete
			end
		end

	has_content (file_path: PATH): BOOLEAN
		do
			file.reset_path (file_path)
			Result := file.count > 0
		end

	make_log_directory
		do
			if attached log.path.parent as parent then
				Environment.make_directory (parent, True)
			end
		end

	put_log_values_differ (file_path: PATH)
		do
			log.put_string ("VALUES DIFFER: " + file_path.out)
			log.put_new_line
		end

	put_results (is_total: BOOLEAN; a_pass_count, a_fail_count: INTEGER)
		local
			passed, failed: STRING
		do
			passed := "Passed: "; failed := " Failed: "
			if is_total then
				across << passed, failed >> as str loop
					str.to_lower
					if str = failed then
						str.remove_head (1)
					end
					str.prepend ("Total ")
					if str = failed then
						str.prepend_character (' ')
					end
				end
			end
			IO.put_new_line
			IO.put_string ("Tested against eXpat"); IO.put_new_line
			IO.put_string (passed + a_pass_count.out)
			IO.put_string (failed + a_fail_count.out)
			IO.put_new_line
		end

feature {NONE} -- Factory

	new_find_results: XT_COMMAND_OUTPUT_FILE
		do
			create Result.make_with_output (Find_template, << dir_path, wild_card >>)
		end

	new_log_path: PATH
		local
			name: STRING
		do
			Result := new_base_log_path
			name := wild_card + ".log"
			name.replace_substring ("dot", 1, 1)
			Result := Result.extended (name)
		end

	new_base_log_path: PATH
		do
			Result := Environment.temporary_path (Environment.command_name)
			if attached dir_path.entry as entry then
				Result := Result.extended (entry.name + "-logs")
			end
		end

feature {NONE} -- Internal attributes

	expat_checksum: NATURAL

	expat_error: STRING

	expat_return_code: INTEGER

	wild_card: STRING

	dir_path: PATH

	parse_status: INTEGER

	log: PLAIN_TEXT_FILE

	file: PLAIN_TEXT_FILE

feature {NONE} -- Constants

	Checksum_comparison: STRING = "Checksum for %S: Xpact=%S eXpat=%S"

	Default_wild_card: STRING = "*.xml"

	Error_template: STRING = "ERROR (%S): %S"

	Find_template: STRING
		once
			Result := "find %S -type f -name '%S'"
		end

	Xml_crc_32: STRING = "xml_crc_32 -type %S -duration 0 %S"
end
