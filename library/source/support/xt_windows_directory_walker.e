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
			is_visited, make_with_path, new_directory
		end

create
	make_with_path, make_root_with_path

feature {NONE} -- Initialization

	make_with_path (dir_path: PATH)
		do
			Precursor (dir_path)
			inode_table := Default_inode_table
		end

	make_root_with_path (dir_path: PATH)
		do
			make_with_path (dir_path)
			create inode_table.make (100_000)
		end

feature -- Element change

	set_inode_table (a_inode_table: like Default_inode_table)
		do
			inode_table := a_inode_table
		end

feature -- Factory

	new_directory (dir_path: PATH): like Current
		do
			create Result.make_with_path (dir_path)
			Result.set_inode_table (inode_table)
		end

feature {NONE} -- Implementation

	is_visited (info: FILE_INFO): BOOLEAN
		do
			inode_table.put (True, info.inode)
			Result := inode_table.conflict
		end

feature {NONE} -- Internal attributes

	inode_table: like Default_inode_table

feature {NONE} -- Constants

	Default_inode_table: HASH_TABLE [BOOLEAN, INTEGER]
		once
			create Result.make (3)
		end
end
