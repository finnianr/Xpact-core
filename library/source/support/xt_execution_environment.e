note
	description: "Extended ${EXECUTION_ENVIRONMENT}."

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-18 09:40:00 GMT (Saturday 18th July 2026)"
	revision: "1"

class
	XT_EXECUTION_ENVIRONMENT

inherit
	EXECUTION_ENVIRONMENT

feature -- Access

	command_name: IMMUTABLE_STRING_32
		local
			index_separator, count: INTEGER; separator: CHARACTER_32
		do
			separator := Operating_environment.Directory_separator
			count := Arguments.Command_name.count
			index_separator := Arguments.Command_name.last_index_of (separator, count)
			if index_separator > 0 then
				Result := Arguments.Command_name.shared_substring (index_separator + 1, count)
			else
				create Result.make_empty
			end
		end

feature -- Basic operations

	do_command (template: STRING; argument_array: ARRAY [ANY])
		local
			s: XT_STRING_ROUTINES; argument_list: ARRAYED_LIST [STRING]
			u: UTF_CONVERTER
		do
			create argument_list.make (argument_array.count)
			across argument_array as arg loop
				if attached {PATH} arg as path then
					argument_list.extend (escaped (path))
				elseif attached {STRING} arg as str then
					argument_list.extend (str)
				else
					argument_list.extend (arg.out)
				end
			end
			if attached s.substitute (template, argument_list.to_array) as utf_8 then
				system (u.utf_8_string_8_to_string_32 (utf_8))
			end
		end

	make_directory (path: PATH; recursively: BOOLEAN)
		do
			Directory.make_with_path (path)
			if not Directory.exists then
				if recursively then
					Directory.recursive_create_dir
				else
					Directory.create_dir
				end
			end
		end

	remove_directory (path: PATH; recursively: BOOLEAN)
		do
			Directory.make_with_path (path)
			if Directory.exists then
				if recursively then
					Directory.recursive_delete
				else
					Directory.delete
				end
			end
		end

	remove_file (file_path: PATH)
		do

		end

feature -- Access

	escaped (a_path: PATH): STRING
		local
			path: STRING
		do
			path := a_path.utf_8_name
			if (path.has (' ') or else across Reserved_path_chars as c some path.has (c) end)
				and then attached Reserved_path_chars as reserved
			then
				create Result.make ((path.count * 1.3).ceiling)
				across path as c loop
					inspect c
						when ' ' then
							Result.extend ('\')
					else
						if reserved.has (c) then
							Result.extend ('\')
						end
					end
					Result.extend (c)
				end
			else
				Result := path
			end
		end

	temporary_path (name: READABLE_STRING_GENERAL): PATH
		do
			if attached Temporary_directory_path as dir_path then
				Result := dir_path.extended (name)
			else
				create Result.make_empty
			end
		end

feature {NONE} -- Constants

	Empty_path: PATH
		once
			create Result.make_empty
		end

	Directory: DIRECTORY
		once
			create Result.make_with_path (Empty_path)
		end

	Reserved_path_chars: STRING = "*?[]<>|&;`$()%"%'!~ %T%N-"
end
