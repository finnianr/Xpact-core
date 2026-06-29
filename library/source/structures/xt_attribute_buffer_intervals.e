note
	description: "[
		List of indices demarking name-value attribute pair substrings in ${XT_XML_PARSER}.buffer
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-22 18:20:41 GMT (Monday 22th June 2026)"
	revision: "1"

class
	XT_ATTRIBUTE_BUFFER_INTERVALS

inherit
	XT_CHARACTER_BUFFER_INTERVALS
		rename
			make as make_sized
		redefine
			copied_buffer, data_offset, is_value, make_sized, on_resize
		end

	XT_SHARED_NAME_CACHE
		undefine
			copy, is_equal
		end

create
	make, make_sized

feature -- Initialization

	make (n: INTEGER; a_name_cache: XT_NAME_CACHE)
		do
			make_sized (n)
			name_cache := a_name_cache
		end

	make_sized (n: INTEGER)
		do
			Precursor (n)
			create character_swap_area.make_empty (n)
			create name_and_value_pointer_pair.make_empty (2)
			create attribute_table.make (11)
			name_cache := Empty_name_cache
		end

feature -- Status query

	is_null_terminated: BOOLEAN
		-- `True' if `null_terminate_values' was called

	swap_area_big_enough: BOOLEAN
		do
			Result := character_swap_area.capacity >= count
		end

	upper_plus_1_characters (buffer: SPECIAL [CHARACTER_8]): STRING
		require
			swap_area_big_enough: swap_area_big_enough
		local
			i, j, i_final, upper_plus_1: INTEGER
		do
			create Result.make_filled ('%U', count)
			if attached area_v2 as l_area and then attached Result.area as str_area then
				i_final := count * Group_size
				from i := 0 until i = i_final loop
					upper_plus_1 := l_area [i + 3] + 1
					str_area [j] := buffer [upper_plus_1]
					i := i + Group_size; j := j + 1
				end
			end
		end

feature -- Status change

	null_terminate_values (buffer: SPECIAL [CHARACTER_8])
		-- temporarily insert null string terminators in `buffer' for later
		-- restoration by`'
		require
			buffer_not_null_terminated: not is_null_terminated
			swap_area_big_enough: swap_area_big_enough
		local
			i, i_final, upper_plus_1: INTEGER
		do
			if attached character_swap_area as swap_area and attached area_v2 as l_area then
				swap_area.wipe_out
				i_final := count * Group_size
				from i := 0 until i = i_final loop
					upper_plus_1 := l_area [i + 3] + 1
					swap_area.extend (buffer [upper_plus_1])
					buffer [upper_plus_1] := '%U'
					i := i + Group_size
				end
			end
			is_null_terminated := True
		end

	undo_null_terminated_values (buffer: SPECIAL [CHARACTER_8])
		require
			buffer_null_terminated: is_null_terminated
			swap_area_big_enough: swap_area_big_enough
		local
			i, j, i_final, upper_plus_1: INTEGER
		do
			if attached character_swap_area as swap_area and attached area_v2 as l_area then
				i_final := count * Group_size
				from i := 0; j := 0 until i = i_final loop
					upper_plus_1 := l_area [i + 3] + 1
					buffer [upper_plus_1] := swap_area [j]
					i := i + Group_size; j := j + 1
				end
			end
			is_null_terminated := False
		end

feature -- Access

	item_c_name_and_value (buffer: SPECIAL [CHARACTER_8]): SPECIAL [POINTER]
		-- Null terminated pointers to a name-value pair
		require
			null_terminated_buffer: is_null_terminated
			swap_area_big_enough: swap_area_big_enough
		do
			Result := name_and_value_pointer_pair
			Result.wipe_out
			if attached item_interval as a then
				Result.extend (name_cache.item (buffer, a [0], a [1]).area.base_address) -- name
				Result.extend (buffer.item_address (a [2])) -- value
			end
		ensure
			same_value: new_c_string (Result [1]).to_string ~ item_value (buffer)
		end

feature -- Contract support

	item_value (buffer: SPECIAL [CHARACTER_8]): STRING
		-- value at current iteration position
		local
			i: INTEGER
		do
			i := index - 1
			Result := buffer_substring (buffer, area_v2 [i + 2], area_v2 [i + 3], False)
		end

feature -- Conversion

	as_table (buffer: SPECIAL [CHARACTER_8]; keep_ref: BOOLEAN): like attribute_table
		-- convert to hash table
		require
			valid_attributes_count: is_valid_count
		do
			Result := attribute_table
			Result.wipe_out
			from start until after loop
				if attached item_interval as a then
					if attached name_cache.item (buffer, a [0], a [1]) as name then
						Result.put (buffer_substring (buffer, a [2], a [3], True), name)
					end
					check
						not_duplicate_name: Result.inserted
					end
				end
				forth
			end
			if keep_ref then
				Result := Result.twin
			end
		ensure
			keep_ref_definition: keep_ref implies Result /= attribute_table
		end

feature {NONE} -- Implementation

	copied_buffer (buffer: SPECIAL [CHARACTER_8]; i, lower_index, a_count: INTEGER): SPECIAL [CHARACTER_8]
		do
			if i.integer_remainder (Group_size) = 0 then
				Result := name_cache.item (buffer, lower_index, lower_index + a_count - 1).area
			else
				Result := Precursor (buffer, i, lower_index, a_count)
			end
		end

	is_value (overflow_index: INTEGER): BOOLEAN
		-- True if `overflow_index' is for a value and not a name
		do
			Result := overflow_index.integer_remainder (2) = 1
		end

	new_c_string (ptr: POINTER): C_NULLED_STRING_8
		do
			create Result.make_from_c (ptr)
		end

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make_sized (n)
		end

	on_resize (a_capacity: INTEGER)
		do
			Precursor (a_capacity)
			character_swap_area := character_swap_area.aliased_resized_area (a_capacity // Group_size)
		end

feature {NONE} -- Internal attributes

	character_swap_area: SPECIAL [CHARACTER_8]

	name_cache: XT_NAME_CACHE
		-- efficient lookup of attribute/tag name

	name_and_value_pointer_pair: SPECIAL [POINTER]

	attribute_table: HASH_TABLE [STRING, STRING]
		-- reuseable table of name-value attribute pairs

feature {NONE} -- Constants

	Data_offset: INTEGER = 2

	Group_size: INTEGER = 4

end
