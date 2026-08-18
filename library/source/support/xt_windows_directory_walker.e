note
	description: "${XT_DIRECTORY_WALKER} that checks for directories already walked using ${FILE_INFO}.inode"
	notes: "[
		**Workaround**
		
		ntfs3 (the newer in-kernel driver you're almost certainly using on Mint 22.2) has historically been
		inconsistent about this. Some reparse points get exposed as regular directories with no symlink marker at all,
		which means your walker's lstat/S_ISLNK check silently passes right through them.
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
