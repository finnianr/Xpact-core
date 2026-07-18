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

	XT_STRING_ROUTINES_I

create
	make

feature {NONE} -- Initialization

	make (a_dir_path: PATH)
		require
			latin_1_path: a_dir_path.name.is_valid_as_string_8
		local
		do
			create wild_card.make_empty
			if attached a_dir_path.entry as last_step and then attached last_step.name as name then
				wild_card := name.to_string_8
				dir_path := a_dir_path.parent
			else
				dir_path := a_dir_path
			end
		end

feature -- Basic operations

	execute
		local
			find_results: XT_COMMAND_OUTPUT_FILE; crc_32: CRC_32_GENERATOR
			file_path: PATH; done: BOOLEAN; checksum: NATURAL; i, count: INTEGER
		do
			create find_results.make_with_output (find_command)
			if find_results.has_output then
				from until done loop
					find_results.read_line
					if find_results.end_of_file then
						done := True
					else
						i := i + 1
						IO.put_integer (i); IO.put_string (". ")
						IO.put_string (find_results.last_string)
						count := 0
						across Parse_data_types as data_type until done loop
							create crc_32.make (data_type)
							create file_path.make_from_string (find_results.last_string)
							crc_32.parse_file (file_path, 0, True)
							checksum := expat_checksum (@ data_type.key, file_path)
							if crc_32.checksum.value = checksum then
								count := count + 1
							else
								IO.put_string (" VALUES DIFFER")
								IO.put_new_line
								IO.put_string (substitute (Checksum_comparison, << @ data_type.key, crc_32.checksum.value.out, checksum.out >>))
								IO.put_new_line
								done := True
							end
						end
						if count = Parse_data_types.count then
							IO.put_string (" OK")
							IO.put_new_line
						end
					end
				end
				find_results.close
			end
		end

feature {NONE} -- Implementation

	find_command: STRING
		do
			if wild_card.is_empty then
				Result := substitute (Find_template, << dir_path.out >>)
			else
				Result := substitute (Find_template_name, << dir_path.out, wild_card >>)
			end
		end

	expat_checksum (type: STRING; file_path: PATH): NATURAL
		local
			checksum_results: XT_COMMAND_OUTPUT_FILE; done: BOOLEAN
			index: INTEGER
		do
			create checksum_results.make_with_output (substitute (Xml_crc_32, << type, file_path.out >>))
			if checksum_results.has_output then
				from until done loop
					checksum_results.read_line
					if checksum_results.end_of_file then
						done := True
					elseif attached checksum_results.last_string as line and then line.starts_with (once "Checksum") then
						index := line.index_of (':', 1)
						Result := line.substring (index + 2, line.count).to_natural
						done := True
					end
				end
				checksum_results.close
			end
		end

feature {NONE} -- Internal attributes

	wild_card: STRING

	dir_path: PATH

	parse_status: INTEGER

feature {NONE} -- Constants

	Checksum_comparison: STRING = "Checksum for %S: Xpact=%S eXpat=%S"

	Find_template: STRING = "find %S -type f"

	Find_template_name: STRING
		once
			Result := Find_template + " -name '%S'"
		end

	Xml_crc_32: STRING = "xml_crc_32 -type %S -duration 0 %S"
end
