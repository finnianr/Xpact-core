note
	description: "Output captured from command into temporary file. Deleted on close"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-18 10:10:00 GMT (Saturday 18th July 2026)"
	revision: "1"

class
	XT_COMMAND_OUTPUT_FILE

inherit
	PLAIN_TEXT_FILE
		export
			{NONE} all
			{ANY} open_read
		end

	XT_SHARED_EXECUTION_ENVIRONMENT

create
	make_with_output

feature {NONE} -- Initialization

	make_with_output (command_template: STRING; argument_array: ARRAY [ANY])
		require
			enough_arguments: command_template.occurrences ('%S') = argument_array.count
			has_space: command_template.has (' ')
		local
			s: XT_STRING_8_ROUTINES; error_file: PLAIN_TEXT_FILE; temp_path: PATH
			checksum: EL_CRC_32_DIGEST; argument_list: ARRAYED_LIST [ANY]
		do
			create error_lines.make (0)
			create checksum
			checksum.add_string (command_template) -- stop clashes
			across argument_array as argument loop
				checksum.add_string (argument.out)
			end
			temp_path := Environment.temporary_command_path
			Environment.make_directory (temp_path, False)

			output_path := temp_path.extended (s.substitute (Output_name_template, << "output", checksum.out >>))
			error_path := temp_path.extended (s.substitute (Output_name_template, << "error", checksum.out >>))

			create argument_list.make_from_array (argument_array)
			argument_list.extend (output_path); argument_list.extend (error_path)
			Environment.do_command (command_template + Redirection_template, argument_list.to_array)

			return_code := Environment.return_code
			if return_code = 0 then
				make_open_read (output_path.name)
				create error_file.make_with_path (error_path)
				error_file.delete
			else
				make_with_path (output_path)
				create error_file.make_open_read (error_path.name)
				if attached error_file as f then
					from until f.end_of_file loop
						f.read_line
						if f.last_string.count > 0 then
							error_lines.extend (f.last_string.twin)
						end
					end
					f.delete; f.close
				end
			end
		end

feature -- Status report

	has_output: BOOLEAN
		do
			Result := exists and then file_readable
		end

	has_errors: BOOLEAN
		do
			Result := return_code > 0
		end

feature -- Access

	return_code: INTEGER

	error_lines: ARRAYED_LIST [STRING]

	first_line: STRING
		do
			create Result.make_empty
			if has_output then
				read_line
				if not end_of_file then
					Result := last_string
				end
			end
		end

	last_path: PATH
		local
			u: UTF_CONVERTER; s: XT_STRING_8_ROUTINES
		do
			if s.is_ascii_string (last_string) then
				create Result.make_from_string (last_string)
			else
				create Result.make_from_string (u.utf_8_string_8_to_string_32 (last_string))
			end
		end

	error_path: PATH

	output_path: PATH

feature -- Basic operations

	append_lines_to (list: ARRAYED_LIST [STRING])
		local
			done: BOOLEAN
		do
			if has_output then
				from until done loop
					read_line
					if end_of_file then
						done := True
					else
						list.extend (last_string.twin)
					end
				end
				cleanup
			end
		end

	cleanup
		do
			if not is_closed then
				close
			end
			delete
		end

feature {NONE} -- Constants

	Redirection_template: STRING
		once
			Result := " > '%S' 2> '%S'"
		ensure
			has_leading_space: Result [1] = ' '
		end

	Output_name_template: STRING = "%S.%S.txt"

end
