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
		rename
			exists as has_output
		redefine
			close
		end

create
	make_with_output

feature {NONE} -- Initialization

	make_with_output (a_command: STRING_8)
		require
			has_space: a_command.has (' ')
		local
			exec_name: STRING; error_path, output_path: PATH
			s: XT_STRING_ROUTINES; error_file: PLAIN_TEXT_FILE
		do
			create error_lines.make (0)
			exec_name := a_command.substring (1, a_command.index_of (' ', 1) - 1)
			output_path := Environ.temporary_path ("output-" + exec_name + ".txt")
			error_path := Environ.temporary_path ("error-" + exec_name + ".txt")
			if attached s.substitute (Command_template, << a_command, output_path.out, error_path.out >>) as command then
				Environ.system (command)
			end
			return_code := Environ.return_code
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
					f.close; f.delete
				end
			end
		end

feature -- Access

	return_code: INTEGER

	error_lines: ARRAYED_LIST [STRING]

feature -- Basic operations

	close
		require else
			has_output: has_output
		do
			Precursor
			delete
		end

feature {NONE} -- Constants

	Environ: XT_EXECUTION_ENVIRONMENT
		once
			create Result
		end

	Command_template: STRING = "%S > '%S' 2> '%S'"

end
