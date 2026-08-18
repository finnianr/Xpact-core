note
	description: "A set of texts for Xpact-core classes"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-06-28 6:31:14 GMT (Sunday 28th June 2026)"
	revision: "1"

class
	XT_TEST_SET

create
	make

feature -- Initialization	

	make
		do
		end

feature -- Basic operations

	execute (name: STRING)
		do
			if attached new_procedure_table as table and then attached table [name] as test then
				test.apply
				if not failed then
					IO.put_string ("Test: " + name + " OK")
				end
			else
				IO.put_string ("No such test: " + name)
			end
			IO.put_new_line
		end

feature -- Tests

	test_buffer_pool
		local
			pool: XT_CHARACTER_BUFFER_POOL; size_table: ARRAY [SPECIAL [CHARACTER_8]]
		do
			create pool.make (20)
			create size_table.make_filled (create {SPECIAL [CHARACTER_8]}.make_empty (0), 2, 10)
			across << 10, 5, 2 >>  as size loop
				size_table [size] := pool.borrow_item (size)
			end
			across << 10, 2, 5 >>  as size loop
				pool.return (size_table [size])
			end
			assert ("count is 3", pool.count = 3)
			assert ("is_sorted_ascending", pool.is_sorted_ascending)
			across << 2, 10, 5 >>  as size loop
				if attached pool.borrow_item (size) as borrowed then
					assert ("size matched", borrowed = size_table [size])
					assert ("count is 2", pool.count = 2)
					pool.return (borrowed)
					assert ("count is 3", pool.count = 3)
					assert ("is_sorted_ascending", pool.is_sorted_ascending)
				end
			end
		end

	test_chunk_reading
		local
			file: RAW_FILE; chunk: SPECIAL [CHARACTER]
		do
			create chunk.make_filled ('%U', Chunk_size)
			create file.make_open_read ("data/Legislation.xml")
			IO.put_string ("Remainder: "); IO.put_integer (file.count \\ Chunk_size)
			IO.put_new_line
			from until file.end_of_file loop
				file.read_data (chunk.base_address, Chunk_size)
				if file.bytes_read = Chunk_size then
					IO.put_character ('.')
				else
					IO.put_new_line
					IO.put_string ("bytes_read: " + file.bytes_read.out)
					IO.put_new_line
				end
			end
			file.close
			if chunk [file.bytes_read - 1] = '%N' then
				IO.put_string ("Ends with '%%N'")
			else
				IO.put_string ("Ends with '"); IO.put_character (chunk [file.bytes_read - 1])
				IO.put_character ('%'')
			end
			IO.put_new_line
		end

	test_file_info
		local
			info: FILE_INFO
		do
			create info.make
			info.set_is_following_symlinks (False)
			across 1 |..| 3 as n loop
				info.update ("/media/finnian/Windows/Program Files/WindowsApps/AppleInc.AppleDevices_1.1540.23042.0_x64__nzyj5cx40ttqa/VFS")
				if info.exists then
					print ("type: " + info.type.out + "%N")
					print ("is_symlink: " + info.is_symlink.out + "%N")
					print ("is_directory: " + info.is_directory.out + "%N")
					print ("device: " + info.device.out + " inode: " + info.inode.out + "%N")
				else
					print ("stat failed%N")
				end
			end
		end

	test_ntfs_link_detection
		local
			f: EL_NTFS_FILE_INFO; windows_root: STRING
		do
			create f.make
			windows_root := "/media/finnian/Windows/"
			f.update (windows_root)
			if f.exists then
				f.update (windows_root + "Program Files/Common Files/System/wab32.dll")
				assert ("is_symlink", f.is_symlink)
				assert ("is_reparse_point", f.is_reparse_point)

				f.update (windows_root + "Program Files/WindowsApps")
				assert ("is_symlink", not f.is_symlink)
				assert ("is_reparse_point", not f.is_reparse_point)

				f.update (windows_root + "Documents and Settings")
				assert ("is_symlink", f.is_symlink)
				assert ("is_reparse_point", f.is_reparse_point)
			else
				assert ("Windows partition mounted", False)
			end
		end

feature -- Status report

	failed: BOOLEAN

feature {NONE} -- Assertions

	assert (a_label: STRING_8; a_condition: BOOLEAN)
			-- Record test failure without hiding later failures.
		do
			if not a_condition then
				failed := True
				io.put_string ("FAIL: ")
				io.put_string (a_label)
				io.put_new_line
			end
		end

feature {NONE} -- Implementation

	new_procedure_table: HASH_TABLE [PROCEDURE, STRING]
		do
			create Result.make_from_iterable_tuples (<<
				[agent test_buffer_pool, "buffer_pool"],
				[agent test_chunk_reading, "chunk_reading"],
				[agent test_file_info, "file_info"],
				[agent test_ntfs_link_detection, "ntfs_link_detection"]
			>>)
		end

feature {NONE} -- Constants

	Chunk_size: INTEGER = 4096

end
