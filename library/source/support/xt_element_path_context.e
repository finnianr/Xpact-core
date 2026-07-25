note
	description: "${XT_ELEMENT_CONTEXT} with path information"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-25 18:15:00 GMT (Saturday 25th July 2026)"
	revision: "1"

class
	XT_ELEMENT_PATH_CONTEXT

inherit
	XT_ELEMENT_CONTEXT
		rename
			make as make_context
		undefine
			copy, is_equal
		redefine
			push, pop
		end

	ARRAYED_STACK [STRING]
		rename
			make as make_stack
		export
			{NONE} all
		redefine
			new_filled_list, is_equal
		end

	HASHABLE
		undefine
			copy, is_equal
		end

create
	make

feature {NONE} -- Initialisation

	make (a_section_ptr: POINTER; n: INTEGER)
		do
			make_context (a_section_ptr)
			make_stack (N)
		end

feature -- Access

	hash_code: INTEGER
		-- Hash code value
		local
			i, i_final: INTEGER
		do
			Result := internal_hash_code
			if Result = 0 and then attached area_v2 as l_area then
					-- The magic number `8388593' below is the greatest prime lower than
					-- 2^23 so that this magic number shifted to the left does not exceed 2^31.
				i_final := count - 1
				from i := 0  until i > i_final loop
					Result := ((Result \\ 8388593) |<< 8) + l_area [i].hash_code
					i := i + 1
				end
				internal_hash_code := Result
			end
		end

feature -- Element change

	push (a_name: STRING)
		do
			Precursor (a_name)
			put (a_name)
			internal_hash_code := 0
		end

	pop
		do
			Precursor
			remove
			internal_hash_code := 0
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
		do
			if other = Current then
				Result := True
			else
				Result := count = other.count and then area_v2.same_items (other.area_v2, 0, 0, count)
			end
		end

feature {NONE} -- Implementation

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (default_pointer, n)
		end

feature {NONE} -- Internal attributes

	internal_hash_code: INTEGER
			-- Cache for `hash_code'.

end
