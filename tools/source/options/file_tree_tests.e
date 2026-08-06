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
	XT_STRING_8_ROUTINES_I

	XT_FILE_ROUTINES_I

	XT_SHARED_EXECUTION_ENVIRONMENT

create
	make

feature {NONE} -- Initialization

	make (a_path: PATH)
		do
			path := a_path
			wild_card := "*.xml"
			if attached a_path.entry as entry then
				wild_card := entry.utf_8_name
				if wild_card.starts_with ("*.") then
					path := a_path.parent
				end
			end
			make_log
			create file.make_with_path (log.path)
			create {XT_DO_NOTHING_FILE_HANDLER} file_handler
		end

	make_log
		do
			create log.make_with_path (new_log_path)
		end

feature -- Access

	fail_count: INTEGER

	pass_count: INTEGER

	sum_fail_count: INTEGER
		do
			Result := fail_count
		end

	sum_pass_count: INTEGER
		do
			Result := pass_count
		end

feature -- Basic operations

	execute
		do
			make_log_directory
			if attached new_find_results (path, wild_card) as find_results then
				if find_results.has_output then
					do_tests (find_results)
					put_results (IO.Output, pass_count, fail_count, False)
				end
				find_results.cleanup
			end
			if not logs_retained then
				Environment.remove_directory (Environment.temporary_command_path, True)
			end
		end

	put_results (medium: PLAIN_TEXT_FILE; a_pass_count, a_fail_count: INTEGER; is_total: BOOLEAN)
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
			medium.put_new_line
			medium.put_string ("Tested against eXpat"); medium.put_new_line
			medium.put_string (passed + a_pass_count.out)
			medium.put_string (failed + a_fail_count.out)
			medium.put_new_line
		end

feature -- Status change

	keep_logs
		do
			logs_retained := True
		end

feature -- Status report

	logs_retained: BOOLEAN

feature -- Element change

	set_file_handler (a_file_handler: XT_FILE_HANDLER)
		do
			file_handler := a_file_handler
		end

feature {NONE} -- Implementation

	do_tests (find_results: XT_COMMAND_OUTPUT_FILE)
		local
			done: BOOLEAN; i: INTEGER
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
						if has_content (file_path) and then attached new_comparison (file_path) as comparison then
							file_handler.do_with (file_path)
							comparison.execute
							if comparison.both_agree then
								comparison.put_status (IO.Output)
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

feature {NONE} -- Factory

	new_comparison (file_path: PATH): XT_EXPAT_COMPARISON
		do
			create Result.make (file_path, log)
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
			Result := Environment.temporary_command_path
			if attached path.entry as entry then
				Result := Result.extended (entry.name + "-logs")
			end
		end

feature {NONE} -- Internal attributes

	wild_card: STRING

	path: PATH
		-- directory or file path

	parse_status: INTEGER

	log: PLAIN_TEXT_FILE

	file: PLAIN_TEXT_FILE

	file_handler: XT_FILE_HANDLER

end
