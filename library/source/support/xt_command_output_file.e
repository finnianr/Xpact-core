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

	make_with_output (command: STRING_8)
		require
			has_space: command.has (' ')
		local
			exec_name: STRING; output_path: PATH
		do
			exec_name := command.substring (1, command.index_of (' ', 1) - 1)
			output_path := Environ.temporary_path ("output-" + exec_name + ".txt")
			Environ.system (command + " > " + output_path.out)
			return_code := Environ.return_code
			if return_code = 0 then
				make_open_read (output_path.name)
			else
				make_with_path (output_path)
			end
		end

feature -- Access

	return_code: INTEGER

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

end
