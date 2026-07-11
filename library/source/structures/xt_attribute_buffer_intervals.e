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
	ARRAYED_LIST [INTEGER]
		rename
			forth as index_forth,
			extend as extend_index,
			count as index_count,
			make as make_sized
		export
			{NONE} all
		undefine
			new_filled_list
		redefine
			make_sized, wipe_out
		end

	XT_STRING_ROUTINES_I
		undefine
			copy, is_equal
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
			create attribute_table.make (11)
			create entity_table.make (11)
			create overflow_buffer_area.make_empty (area.capacity // 2)
			name_cache := Empty_name_cache
		end

feature -- Status query

	is_valid_count: BOOLEAN
		-- `index_count' is multiple of `Group_size'
		do
			Result := index_count \\ Group_size = 0
		end

	is_null_terminated: BOOLEAN
		-- `True' if `null_terminate_values' was called

	swap_area_big_enough: BOOLEAN
		do
			Result := character_swap_area.capacity >= count
		end

feature -- Access

	entity_table: HASH_TABLE [STRING, STRING]
		-- table of expanded entities defined in DOCTYPE by ENTITY

	upper_plus_1_characters (buffer: SPECIAL [CHARACTER_8]): STRING
		require
			swap_area_big_enough: swap_area_big_enough
		local
			i, j, i_final, upper_plus_1: INTEGER
		do
			create Result.make_filled ('%U', count)
			if attached area_v2 as l_area and then attached Result.area as str_area
				and then attached overflow_buffer_area as overflow_area
			then
				from i := 0; i_final := index_count until i = i_final loop
					upper_plus_1 := l_area [i + 3] + 1
					str_area [j] := i_th_buffer (i, buffer, overflow_area) [upper_plus_1]
					i := i + Group_size; j := j + 1
				end
			end
		end

feature -- Status change

	null_terminate_values (a_buffer: SPECIAL [CHARACTER_8])
		-- temporarily insert null string terminators in `buffer' for later
		-- restoration by `undo_null_terminated_values'
		require
			buffer_not_null_terminated: not is_null_terminated
			swap_area_big_enough: swap_area_big_enough
		local
			i, i_final, upper_plus_1: INTEGER
		do
			if attached character_swap_area as swap_area and attached area_v2 as l_area
				and then attached overflow_buffer_area as overflow_area
			then
				swap_area.wipe_out
				from i := 0; i_final := index_count until i = i_final loop
					upper_plus_1 := l_area [i + 3] + 1
					if attached i_th_buffer (i, a_buffer, overflow_area) as buffer then
						swap_area.extend (buffer [upper_plus_1])
						buffer [upper_plus_1] := '%U'
					end
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
			if attached character_swap_area as swap_area and attached area_v2 as l_area
				and then attached overflow_buffer_area as overflow_area
			then
				from i := 0; j := 0; i_final := index_count until i = i_final loop
					upper_plus_1 := l_area [i + 3] + 1
					i_th_buffer (i, buffer, overflow_area) [upper_plus_1] := swap_area [j]
					i := i + Group_size
					j := j + 1
				end
			end
			is_null_terminated := False
		end

feature -- Measurement

	count: INTEGER
		-- count of interval groups
		do
			Result := index_count // Group_size
		end

	character_count: INTEGER
		-- sum of all substring interval counts
		local
			i, l_count: INTEGER
		do
			if attached area as l_area then
				l_count := l_area.count
				from until i = l_count loop
					Result := Result + l_area [i + 1] - l_area [i] + 1
					i := i + 2
				end
			end
		end

	overflow_buffers_count: INTEGER
		do
			Result := overflow_buffer_area.count
		end

feature -- Constants

	Group_size: INTEGER = 4
		-- number of array items needed to hold intervals of one name-value pair

feature -- Basic operations

	append_pointers_to (c_string_array: SPECIAL [POINTER]; a_buffer: SPECIAL [CHARACTER_8])
		-- append alternating name and value strings to `c_string_array' as pointers to null terminated C strings
		-- and terminated with a null pointer
		require
			null_terminated: is_null_terminated
			empty_c_string_array: c_string_array.count = 0
			big_enough: c_string_array.capacity >= count * 2 + 1
		local
			i, i_final: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			if attached area_v2 as l_area and then attached overflow_buffer_area as overflow_area
				and then attached name_cache as names
			then
				from i := 0; i_final := index_count until i = i_final loop
					buffer := i_th_buffer (i, a_buffer, overflow_area)
					if attached names.item (buffer, l_area [0], l_area [1]) as name then
						c_string_array.extend (name.area.base_address) -- name
					end
					c_string_array.extend (buffer.item_address (l_area [2])) -- value
					i := i + Group_size
				end
				c_string_array.extend (default_pointer)
			end
		ensure
			filled: c_string_array.count = count * 2 + 1
			same_character_count: sum_c_string_lengths (c_string_array) = character_count
		end

	append_values_to_crc_32 (checksum: EL_CRC_32_DIGEST; a_buffer: SPECIAL [CHARACTER_8])
		local
			i, i_final: INTEGER
		do
			if attached area_v2 as l_area and then attached overflow_buffer_area as overflow_area then
				from i := 0; i_final := index_count until i = i_final loop
					checksum.add_characters (i_th_buffer (i, a_buffer, overflow_area), l_area [i + 2], l_area [i + 3])
					i := i + Group_size
				end
			end
		end

	shift_buffer_left (buffer: SPECIAL [CHARACTER_8]; offset: INTEGER)
		-- Slide all live content left by `a_offset' bytes and adjust every index that points into `buffer'.
		local
			i, i_final, shifted_lower_index, lower_index, upper_index, l_count: INTEGER
		do
			if attached overflow_buffer_area as overflow and attached area_v2 as l_area then
			-- iterate over each name and value interval
				from i := 0; i_final := index_count until i = i_final loop
					lower_index := l_area [i]; upper_index := l_area [i + 1]
					shifted_lower_index := lower_index - offset
					if shifted_lower_index < 0 then
					-- no longer fits in `buffer' so make a temporary copy to use instead
						if overflow [i // 2] = Void then
							l_count := upper_index - lower_index + 1
							l_area [i] := 0; l_area [i + 1] := l_count - 1
							overflow [i // 2] := copied_buffer (buffer, i, lower_index, l_count)
						end
					else
					-- still fits in current `buffer`
						l_area [i] := shifted_lower_index; l_area [i + 1] := upper_index - offset
					end
					i := i + 2
				end
			end
		ensure
			all_valid: all_valid
		end

	transfer (additions: like area)
		-- move contents of `additions' into `area'
		require
			full_buffer: additions.count = Group_size
			valid_intervals: valid_intervals (additions)
		local
			i, l_count, new_capacity: INTEGER; l_area: like area_v2
		do
			l_area := area_v2
			i := l_area.count + additions.count
			if i > l_area.capacity then
				new_capacity := i + additional_space
				if new_capacity.integer_remainder (2) = 1 then
					new_capacity := new_capacity + 1
				end
				l_area := l_area.aliased_resized_area (new_capacity)
				area_v2 := l_area
				check
					even_number: new_capacity.integer_remainder (2) = 0
				end
				overflow_buffer_area := overflow_buffer_area.aliased_resized_area (new_capacity // 2)
				character_swap_area := character_swap_area.aliased_resized_area (new_capacity // Group_size)
			end
			l_area.copy_data (additions, 0, index_count, additions.count)
			if attached overflow_buffer_area as overflow then
				l_count := Group_size // 2
				from i := 0 until i = l_count loop
					overflow.extend (Void)
					i := i + 1
				end
			end
			additions.wipe_out
		ensure
			empty_additions_buffer: additions.count = 0
			all_valid: all_valid
		end

	wipe_out
		local
			i, i_final: INTEGER
		do
			index := 0
			if attached overflow_buffer_area as overflow then
			-- recycle value buffers
				from i := 1; i_final := overflow.count until i > i_final loop
					if attached overflow [i] as buffer then
						Buffer_pool.return (buffer)
					end
					i := i + 2
				end
				overflow.wipe_out
			end
			area.wipe_out
		end

feature -- Contract support

	all_valid: BOOLEAN
		-- `True' if all intervals are valid
		do
			Result := valid_intervals (area_v2)
		end

	sum_c_string_lengths (c_string_array: SPECIAL [POINTER]): INTEGER
		local
			i: INTEGER; c_str: C_STRING
		do
			create c_str.make_empty (0)
			from until i = c_string_array.count loop
				if c_string_array [i] = default_pointer then
					i := c_string_array.count -- break
				else
					c_str.set_shared_from_pointer (c_string_array [i])
					Result := Result + c_str.count
					i := i + 1
				end
			end
		end

	item_value (buffer: SPECIAL [CHARACTER_8]): STRING
		-- value at current iteration position
		local
			i: INTEGER
		do
			i := index - 1
			Result := area_substring (buffer, area_v2 [i + 2], area_v2 [i + 3], False)
		end

	valid_intervals (a_area: like area): BOOLEAN
		-- `True' if all intervals are valid
		local
			i, l_count: INTEGER
		do
			l_count := a_area.count
			from Result := True until i = l_count or not Result loop
				if (a_area [i + 1] + 1) >= a_area [i] then
					i := i + 2
				else
					Result := False
				end
			end
		end

feature -- Conversion

	as_table (a_buffer: SPECIAL [CHARACTER_8]; keep_ref: BOOLEAN): like attribute_table
		-- convert all values to hash table keyed by names
		require
			valid_attributes_count: is_valid_count
		local
			i, i_final, amp_index, colon_index: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			Result := attribute_table
			Result.wipe_out
			if attached area_v2 as l_area and then attached overflow_buffer_area as overflow_area then
				from i := 0; i_final := index_count until i = i_final loop
					buffer := i_th_buffer (i, a_buffer, overflow_area)
					if attached name_cache.item (buffer, l_area [i], l_area [i + 1]) as name then
						if attached area_substring (buffer, l_area [i + 2], l_area [i + 3], True) as value then
							amp_index := value.index_of ('&', 1)
							if amp_index > 0 then
								colon_index := value.index_of (';', amp_index + 1)
								if colon_index > 0 and then colon_index > amp_index + 1 then
									Result.put (expanded_value (entity_table, value, amp_index, colon_index), name)
								else
									Result.put (value, name)
								end
							else
								Result.put (value, name)
							end
						end
					end
					check
						not_duplicate_name: Result.inserted
					end
					i := i + Group_size
				end
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
				Result := Buffer_pool.borrow_item (a_count)
				Result.wipe_out
				Result.copy_data (buffer, lower_index, 0, a_count)
			end
		end

	expanded_value (table: like entity_table; value: STRING; a_amp_index, a_colon_index: INTEGER): STRING
		local
			amp_index, colon_index: INTEGER; done: BOOLEAN
		do
			Result := value
			from amp_index := a_amp_index; colon_index := a_colon_index until done loop
				if attached Result.substring (amp_index + 1, colon_index - 1) as entity
					and then attached table [entity] as entity_value
				then
					Result.replace_substring (entity_value, amp_index, colon_index)
					colon_index := colon_index + entity_table.count - 2
				end
				amp_index := Result.index_of ('&', colon_index + 1)
				if amp_index > 0 then
					colon_index := Result.index_of (';', amp_index + 1)
					if colon_index > 0 and then colon_index > amp_index + 1 then
						do_nothing
					else
						done := True
					end
				else
					done := True
				end
			end
		end

	i_th_buffer (i: INTEGER; buffer: SPECIAL [CHARACTER_8]; overflow_area: like overflow_buffer_area): SPECIAL [CHARACTER_8]
		do
			if attached overflow_area [i // 2] as overflow then
				Result := overflow
			else
				Result := buffer
			end
		end

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make_sized (n)
		end

feature {NONE} -- Internal attributes

	attribute_table: HASH_TABLE [STRING, STRING]
		-- reuseable table of name-value attribute pairs

	character_swap_area: SPECIAL [CHARACTER_8]

	name_cache: XT_NAME_CACHE
		-- efficient lookup of attribute/tag name

	overflow_buffer_area: SPECIAL [detachable SPECIAL [CHARACTER_8]]

feature {NONE} -- Constants

	Buffer_pool: XT_CHARACTER_BUFFER_POOL
		once
			create Result.make (10)
		end

invariant
	lower_upper_pairs: index_count.integer_remainder (Group_size) = 0
	proportional_overflow_buffer_capacity: overflow_buffer_area.capacity = area.capacity // 2

end
