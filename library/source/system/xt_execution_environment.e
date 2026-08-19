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
			index_separator, count: INTEGER
			name: IMMUTABLE_STRING_32
		do
			name := Arguments.Command_name
			count := name.count
			index_separator := name.last_index_of (Separator, count)
			if index_separator > 0 then
				Result := name.shared_substring (index_separator + 1, count)
			else
				Result := name
			end
		end

	file_system_module (a_dir_path: PATH): STRING
		-- name of file system module that is used to access `dir_path'
		-- Eg. ext4, fuseblk, ntfs3
		require
			has_root: a_dir_path.has_root
		local
			find_mnt_command: XT_COMMAND_OUTPUT_FILE; dir_path: PATH
			done: BOOLEAN; step_count: INTEGER
		do
			create Result.make_empty
			step_count := a_dir_path.name.occurrences (Separator) + 1
			from dir_path := a_dir_path until done or step_count = 0 loop
				create find_mnt_command.make_with_output ("findmnt -no FSTYPE %S", << dir_path >>)
				if not find_mnt_command.has_errors then
					Result := find_mnt_command.first_line
					find_mnt_command.cleanup
					done := True
				else
					dir_path := dir_path.parent
					step_count := step_count - 1
				end
			end
		end

feature -- Status query

	is_ntfs_path (dir_path: PATH): BOOLEAN
		-- `True' if `dir_path' is on NTFS file system
		local
			find_ntfs_command: XT_COMMAND_OUTPUT_FILE; empty_array: ARRAY [ANY]
			index_root_slash: INTEGER; done: BOOLEAN
		do
			create empty_array.make_empty
			create find_ntfs_command.make_with_output ("lsblk -f | grep -i ntfs", empty_array)
			if attached find_ntfs_command as ntfs and then ntfs.has_output then
				from until done loop
					ntfs.read_line
					if ntfs.end_of_file then
						done := True

					elseif attached ntfs.last_string as line then
						index_root_slash := line.index_of ('/', 1)
						if index_root_slash > 0 and then attached line.substring (index_root_slash, line.count) as mount_path then
							if dir_path.name.starts_with_general (mount_path) then
								Result := True; done := True
							end
						end
					end
				end
				ntfs.cleanup
			end
		end

	file_exists (path: PATH; a_medium: detachable IO_MEDIUM): BOOLEAN
		do
			File.reset_path (path)
			Result := File.exists
			if not Result and then attached a_medium as medium then
				medium.put_string ("File not found: ")
				medium.put_string (path.utf_8_name)
				medium.put_new_line
			end
		end

	directory_exists (path: PATH; a_medium: detachable IO_MEDIUM): BOOLEAN
		do
			Directory.make_with_path (path)
			Result := Directory.exists
			if not Result and then attached a_medium as medium then
				medium.put_string ("Directory not found: ")
				medium.put_string (path.utf_8_name)
				medium.put_new_line
			end
		end

feature -- Basic operations

	do_command (template: STRING; argument_array: ARRAY [ANY])
		local
			s: XT_STRING_8_ROUTINES; argument_list: ARRAYED_LIST [STRING]
			u: UTF_CONVERTER; command: STRING
		do
			create argument_list.make (argument_array.count)
			across argument_array as arg loop
				if attached {PATH} arg as path then
					argument_list.extend (unix_escaped (path))

				elseif attached {STRING} arg as str then
					if s.is_ascii_string (str) or else u.is_valid_utf_8_string_8 (str) then
						argument_list.extend (str)
					else
						argument_list.extend (u.utf_32_string_to_utf_8_string_8 (str))
					end
				else
					argument_list.extend (arg.out)
				end
			end
			command := s.substitute (template, argument_list.to_array)
			if s.is_ascii_string (command) then
				system (command)
			else
				system (u.utf_8_string_8_to_string_32 (command))
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
			if attached File as f then
				f.reset_path (file_path)
				f.open_read
				f.delete
				f.close
			end
		end

feature -- Access

	unix_escaped (a_path: PATH): STRING
		-- path escaped for Unix bash shell
		local
			path: STRING
		do
			path := a_path.utf_8_name
			if attached Reserved_path_chars as reserved and then
				across path as c some
					(not c.is_alpha_numeric implies c = ' ' or else reserved.has (c))
				end
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

	temporary_command_path: PATH
		do
			Result := temporary_path (command_name)
		end

	temporary_path (name: READABLE_STRING_GENERAL): PATH
		do
			if attached Temporary_directory_path as dir_path then
				Result := dir_path.extended (name)
			else
				create Result.make_empty
			end
		end

feature -- Constants

	Separator: CHARACTER
		once
			Result := Operating_environment.Directory_separator
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

	File: RAW_FILE
		once
			create Result.make_with_name ("none.dat")
		end

	Reserved_path_chars: STRING = "*?[]<>|&;`$()%"%'!~ %T%N-"

end
