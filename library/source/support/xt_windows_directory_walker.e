note
	description: "${XT_DIRECTORY_WALKER} that checks for directories already walked using ${FILE_INFO}.inode"
	notes: "[
		**WARNING**

		Use only in readonly mode with safe `mount' args:
		
			modprobe ntfs3
			mount -t ntfs3 /dev/<name> <path> -o ro,noatime,uid=$(id -u),gid=$(id -g)
	
	]"
	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-05 07:00:00 GMT (Wednesday 5th August 2026)"
	revision: "1"

class
	XT_WINDOWS_DIRECTORY_WALKER

inherit
	XT_DIRECTORY_WALKER
		redefine
			file_info, is_directory_symlink
		end

create
	make_with_path

feature {NONE} -- Implementation

	is_directory_symlink (info: like file_info): BOOLEAN
		do
			Result := info.is_directory and then (info.is_symlink or info.is_reparse_point)
		end

feature {NONE} -- Internal attributes

	file_info: EL_NTFS_FILE_INFO

end
