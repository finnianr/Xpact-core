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
			create procedure_table.make (10)
			procedure_table.put (agent test_buffer_pool, "buffer_pool")
		end

feature -- Basic operations

	execute (name: STRING)
		do
			if procedure_table.has_key (name) and then attached procedure_table.found_item as test then
				test.apply
			end
			if not failed then
				io.put_string ("Test: " + name + " OK")
				io.put_new_line
			end
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

feature {NONE} -- Internal attributes

	procedure_table: HASH_TABLE [PROCEDURE, STRING]

end
