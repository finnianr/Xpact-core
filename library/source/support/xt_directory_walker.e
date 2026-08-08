note
	description: "${DIRECTORY} accessible to ${FILE_SYSTEM_XML_HUNTER}"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-05 07:00:00 GMT (Wedsday 5th August 2026)"
	revision: "1"

class
	XT_DIRECTORY_WALKER

inherit
	DIRECTORY
		rename
			File_info as Shared_file_info,
			name as directory_name,
			path as directory_path
		redefine
			make_with_path
		end

create
	make_with_path

feature {NONE} -- Initialization

	make_with_path (dir_path: PATH)
		do
			Precursor (dir_path)
			create file_info.make
			file_info.set_is_following_symlinks (False)
		end

feature -- Basic operations

	traverse (handler: XT_FILE_HANDLER)
		local
			done: BOOLEAN; ptr: POINTER; sub_directory: XT_DIRECTORY_WALKER
		do
			open_read
			from start until done loop
				ptr := eif_dir_next (directory_pointer)
				if ptr.is_default_pointer then
					done := True

				elseif attached new_file_info (ptr) as info and then attached info.file_entry as path then
					if info.is_directory then
						sub_directory := new_directory (path)
						if sub_directory /~ Tmp_path then
							sub_directory.traverse (handler)
						end
					else
						handler.do_with (path)
					end
				end
			end
			close
		end

feature -- Factory

	new_directory (dir_path: PATH): like Current
		do
			create Result.make_with_path (dir_path)
		end

feature {NONE} -- Implementation

	new_file_info (ptr: POINTER): detachable FILE_INFO
		-- file info for `ptr' but only if entry is not a symlink or one of `<< "..", "." >>'
		-- and the entry is readable
		local
			name: STRING_32
		do
			Result := file_info
			name := Result.pointer_to_file_name_32 (ptr)
			Result.update (directory_path.extended (name).name)
			if is_visited (Result) then
				Result := Void

			elseif not Result.exists then
				Result := Void

			elseif not Result.is_ready then
				Result := Void

			elseif not Result.is_access_readable then
				Result := Void

			elseif Result.is_symlink then
				Result := Void

			elseif Result.is_character or Result.is_device or else Result.is_fifo or else Result.is_socket then
				Result := Void

			elseif current_or_parent (name) then
				Result := Void
			end
		end

	current_or_parent (a_name: STRING_32): BOOLEAN
		do
			inspect a_name.count
				when 1 then
					Result := a_name.occurrences ('.') = 1
				when 2 then
					Result := a_name.occurrences ('.') = 2
			else
			end
		end

	is_visited (info: FILE_INFO): BOOLEAN
		do
			Result := False
		end

feature {NONE} -- Internal attributes

	file_info: FILE_INFO

feature {NONE} -- Constants

	Tmp_path: PATH
		once
			create Result.make_from_string ("/tmp")
		end
end
