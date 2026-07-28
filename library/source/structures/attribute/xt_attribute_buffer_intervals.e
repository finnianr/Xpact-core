note
	description: "[
		List of indices demarking name-value attribute pair substrings in ${XT_XML_PARSER_BASE}.buffer
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-22 18:20:41 GMT (Monday 22th June 2026)"
	revision: "1"

deferred class
	XT_ATTRIBUTE_BUFFER_INTERVALS

inherit
	XT_ATTRIBUTE_INTERVAL_LIST

	XT_STRING_ROUTINES_I
		export
			{XT_XML_PARSER_BASE} all
		undefine
			copy, is_equal
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
			Result := character_swap_area.count >= count
		end

feature -- Access

	first_name (buffer: SPECIAL [CHARACTER_8]): STRING
		require
			not_empty: count > 0
		do
			if attached area_v2 as a and then a.count >= Group_size then
				Result := name_cache.item (buffer, a [0], a [1])
			else
				Result := Empty_string
			end
		end

	first_value (buffer: SPECIAL [CHARACTER_8]): STRING
		require
			not_empty: count > 0
		do
			if attached area_v2 as a and then a.count >= Group_size then
				Result := new_substring (buffer, a [2], a [3])
			else
				Result := Empty_string
			end
		end

	upper_plus_1_characters (buffer: SPECIAL [CHARACTER_8]): STRING
		require
			swap_area_big_enough: swap_area_big_enough
		local
			i, j, i_final, upper_plus_1: INTEGER
		do
			create Result.make_filled ('%U', count)
			if attached area_v2 as a and then attached Result.area as str_area
				and then attached overflow_buffer_area as overflow_area
			then
				from i := 0; i_final := index_count until i = i_final loop
					upper_plus_1 := a [i + 3] + 1
					str_area [j] := i_th_value (i, buffer, overflow_area) [upper_plus_1]
					i := i + Group_size; j := j + 1
				end
			end
		end

feature -- UTF-8 Conversion

	utf_8_converted (
		buf: SPECIAL [CHARACTER_8]; start_index, end_index, byte_count: INTEGER; a_pool: detachable like buffer_pool

	): SPECIAL [CHARACTER]
		-- UTF-8 conversion using recylable character buffer arrays
		require
			correct_byte_count: utf_8_bytes_count (buf, start_index, end_index) = byte_count
		do
			if attached a_pool as pool then
				Result := pool.borrow_item (byte_count)
			else
				Result := utf_8_buffer
			end
			Result.wipe_out
			if byte_count > Result.capacity then
				create Result.make_empty (byte_count)
				utf_8_buffer := Result
			end
			to_utf_8 (buf, Result, start_index, end_index)
		ensure
			correct_byte_count: byte_count = Result.count
		end

	as_utf_8 (source: STRING; keep_ref: BOOLEAN): STRING
		local
			utf_8_count: INTEGER
		do
			Result := Output_buffer
			Result.wipe_out
			utf_8_count := utf_8_bytes_count (source.area, 0, source.count - 1)
			Result.grow (utf_8_count)
			Result.area.wipe_out
			to_utf_8 (source.area, Result.area, 0, source.count - 1)
			Result.area.extend ('%U')
			Result.set_count (utf_8_count)
			if keep_ref then
				Result := Result.twin
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
			i, j, i_final, upper_plus_1: INTEGER
		do
			if attached character_swap_area as swap_area and attached area_v2 as a
				and then attached overflow_buffer_area as overflow_area
			then
				from i := 0; i_final := index_count until i = i_final loop
					upper_plus_1 := a [i + 3] + 1
					if attached overflow_area [i // 2 + 1] as overflow then
						overflow [upper_plus_1] := '%U'
					else
						swap_area [j] := a_buffer [upper_plus_1] -- store current value in swap area
						a_buffer [upper_plus_1] := '%U'
					end
					i := i + Group_size; j := j + 1
				end
			end
			is_null_terminated := True
		end

	undo_null_terminated_values (buffer: SPECIAL [CHARACTER_8])
		require
			buffer_null_terminated: is_null_terminated
			swap_area_big_enough: swap_area_big_enough
		local
			i, j, i_final: INTEGER
		do
			if attached character_swap_area as swap_area and attached area_v2 as a
				and then attached overflow_buffer_area as overflow_area
			then
				from i := 0; j := 0; i_final := index_count until i = i_final loop
					inspect swap_area [j]
						when '%U' then
							do_nothing
					else
						buffer [a [i + 3] + 1] := swap_area [j] -- restore original value
						swap_area [j] := '%U'
					end
					i := i + Group_size
					j := j + 1
				end
			end
			is_null_terminated := False
		ensure
			character_swap_area_in_default_state: character_swap_area.filled_with ('%U', 0, count - 1)
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
			if attached area as a then
				l_count := a.count
				from until i = l_count loop
					Result := Result + a [i + 1] - a [i] + 1
					i := i + 2
				end
			end
		end

	overflow_buffers_count: INTEGER
		do
			Result := overflow_buffer_area.count
		end

	utf_8_bytes_count (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
			-- Number of bytes necessary to encode in UTF-8 `s.substring (start_index, end_index)'.
			-- Note that this feature can be used for both escaped and non-escaped string.
			-- In the case of escaped strings, the result will be possibly higher than really needed.
			-- It does not include the terminating null character.
		require
			end_index_big_enough: start_index <= end_index + 1
			valid_start_index: buf.valid_index (start_index)
			valid_end_index: buf.valid_index (end_index)
		deferred
		end

feature -- Basic operations

	append_utf_8_to_crc_32 (checksum: EL_CRC_32_DIGEST; buf: SPECIAL [CHARACTER_8]; start_index, end_index: INTEGER; a_force: BOOLEAN)
		local
			utf_8_count: INTEGER
		do
			utf_8_count := utf_8_bytes_count (buf, start_index, end_index)
			if not a_force implies utf_8_count = end_index - start_index + 1  then
				checksum.add_characters (utf_8_converted (buf, start_index, end_index, utf_8_count, Void), 0, utf_8_count - 1)
			end
		end

	append_first_value_to_crc_32 (checksum: EL_CRC_32_DIGEST; a_buffer: SPECIAL [CHARACTER_8])
		require
			not_empty: count > 0
		local
			lower_index, upper_index, utf_8_count: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area then
				buffer := i_th_value (0, a_buffer, overflow_area)
				lower_index := a [2]; upper_index := a [3]
				utf_8_count := utf_8_bytes_count (buffer, lower_index, upper_index)
				if utf_8_count > upper_index - lower_index + 1 then
					buffer := utf_8_converted (buffer, lower_index, upper_index, utf_8_count, Void)
					lower_index := 0; upper_index := buffer.count - 1
				end
				checksum.add_characters (buffer, lower_index, upper_index)
			end
		end

	append_pointers_to (c_string_array: SPECIAL [POINTER]; a_buffer: SPECIAL [CHARACTER_8])
		-- append alternating name and value strings to `c_string_array' as pointers to null terminated C strings
		-- and terminated with a null pointer
		require
			null_terminated: is_null_terminated
			empty_c_string_array: c_string_array.count = 0
			big_enough: c_string_array.capacity >= count * 2 + 1
		local
			i, j, i_final, lower_index, upper_index, utf_8_count: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached name_cache as names and then attached buffer_pool as pool
			then
				from i := 0; j := 1; i_final := index_count until i = i_final loop
					buffer := i_th_name (i, a_buffer, overflow_area)
					c_string_array.extend (names.item (buffer, a [0], a [1]).area.base_address) -- name
					buffer := i_th_value (i, a_buffer, overflow_area)
					lower_index := a [2]; upper_index := a [3]

					utf_8_count := utf_8_bytes_count (buffer, lower_index, upper_index)
					if utf_8_count > upper_index - lower_index + 1 then
						buffer := utf_8_converted (buffer, lower_index, upper_index, utf_8_count, pool)
						if attached overflow_area [j] as old_buffer then
							pool.return (old_buffer)
						end
						overflow_area [j] := buffer -- gets recycled during wipeout
						lower_index := 0; upper_index := buffer.count - 1
						buffer [buffer.count] := '%U'
					end
					c_string_array.extend (buffer.item_address (lower_index)) -- value
					i := i + Group_size; j := j + 2
				end
				c_string_array.extend (default_pointer)
			end
		ensure
			filled: c_string_array.count = count * 2 + 1
			same_character_count: sum_c_string_lengths (c_string_array) = character_count
		end

	append_values_to_crc_32 (
		checksum: EL_CRC_32_DIGEST; a_buffer: SPECIAL [CHARACTER_8]; default_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE]
	)
		require
			all_default_values_unchecked: across default_values as value all not value.checked end
		local
			i, j, i_final, lower_index, upper_index, utf_8_count: INTEGER; buffer: SPECIAL [CHARACTER_8]
			attribute_: XT_DEFAULT_ATTRIBUTE_VALUE
		do
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached entity_refs_area as entity_refs and then attached entity_table as table
				and then attached name_cache as names
			then
				from i := 0; i_final := index_count until i = i_final loop
					if default_values.count > 0 then
						buffer := i_th_name (i, a_buffer, overflow_area)
						check_value (names.item (buffer, a [i], a [i + 1]), default_values)
					end
					buffer := i_th_value (i, a_buffer, overflow_area)
					lower_index := a [i + 2]; upper_index := a [i + 3]
					utf_8_count := utf_8_bytes_count (buffer, lower_index, upper_index)
					if char_width = 2 or else utf_8_count > upper_index - lower_index + 1 then
						buffer := utf_8_converted (buffer, lower_index, upper_index, utf_8_count, Void)
						lower_index := 0; upper_index := buffer.count - 1
					end
					if attached entity_refs [i // Group_size] as entity_list then
						table.mix_in_values_to_crc_32 (checksum, buffer, entity_list, lower_index, upper_index)
					else
						checksum.add_characters (buffer, lower_index, upper_index)
					end
					i := i + Group_size
				end
			-- Add default values for unchecked
				from j := 0 until j = default_values.count loop
					attribute_ := default_values [j]
					if not attribute_.checked then
						checksum.add_string (attribute_.value)
					end
					j := j + 1
				end
			end
		end

	shift_buffer_left (buffer: SPECIAL [CHARACTER_8]; offset: INTEGER)
		-- Slide all live content left by `a_offset' bytes and adjust every index that points into `buffer'.
		local
			i, j, i_final, shifted_lower_index, lower_index, upper_index, l_count: INTEGER
		do
--			io.put_string ("shift_buffer_left"); io.put_new_line
			if attached overflow_buffer_area as overflow and attached area_v2 as a
				and then attached buffer_pool as pool
			then
			-- iterate over each name and value interval
				from i := 0; j := 0; i_final := index_count until i = i_final loop
					lower_index := a [i]; upper_index := a [i + 1]
					shifted_lower_index := lower_index - offset
					if shifted_lower_index < 0 then
					-- no longer fits in `buffer' so make a temporary copy to use instead
						l_count := upper_index - lower_index + 1
						a [i] := 0; a [i + 1] := l_count - 1
						if j.integer_remainder (2) = 0 then
							overflow [j] := name_cache.item (buffer, lower_index, upper_index).area

						elseif attached pool.borrow_item (l_count) as l_buffer then
							l_buffer.wipe_out
							l_buffer.copy_data (buffer, lower_index, 0, l_count)
							overflow [j] := l_buffer
						end
					else
					-- still fits in current `buffer`
						a [i] := shifted_lower_index; a [i + 1] := upper_index - offset
					end
					i := i + 2; j := j + 1
				end
			end
		ensure
			all_valid: all_valid
		end

	transfer (additions: like area; entity_list: ARRAYED_LIST [STRING])
		-- transfer contents of `additions' into `area' and contents of `entity_list'
		-- into `entity_refs_area'
		require
			full_buffer: additions.count = Group_size
			valid_intervals: valid_intervals (additions)
		local
			i, new_capacity: INTEGER; a: like area_v2
		do
			a := area_v2
			i := a.count + additions.count
			if i > a.capacity then
				new_capacity := i + additional_space
				if new_capacity.integer_remainder (2) = 1 then
					new_capacity := new_capacity + 1
				end
				a := a.aliased_resized_area (new_capacity)
				area_v2 := a
				check
					even_number: new_capacity.integer_remainder (2) = 0
				end
				overflow_buffer_area := overflow_buffer_area.aliased_resized_area (new_capacity // 2)
				entity_refs_area := entity_refs_area.aliased_resized_area (new_capacity // Group_size)
				character_swap_area := character_swap_area.aliased_resized_area_with_default ('%U', new_capacity // Group_size)
			end
			a.copy_data (additions, 0, index_count, additions.count)
			if attached overflow_buffer_area as overflow then
				overflow.extend (Void); overflow.extend (Void)
			end
			if entity_list.count > 0 and then attached entity_refs_pool as pool then
				if pool.count > 0 and then attached pool.item as pool_entity_buffer then
					pool.remove
					check
						is_empty_buffer: pool_entity_buffer.is_empty
					end
					pool_entity_buffer.append (entity_list)
					entity_refs_area.extend (pool_entity_buffer)
				else
					entity_refs_area.extend (entity_list.twin)
				end
			else
				entity_refs_area.extend (Void)
			end
			additions.wipe_out; entity_list.wipe_out
		ensure
			empty_additions_buffer: additions.count = 0
			empty_entity_list_buffer: entity_list.count = 0
			all_valid: all_valid
		end

feature -- Debug helpers

	has_value (a_buffer: SPECIAL [CHARACTER_8]; name, value: STRING): BOOLEAN
		local
			i, i_final: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached name_cache as names
			then
				from i := 0; i_final := index_count until i = i_final or Result loop
					buffer := i_th_name (i, a_buffer, overflow_area)
					if name_cache.item (buffer, a [i], a [i + 1]) ~ name then
						buffer := i_th_value (i, a_buffer, overflow_area)
						if area_substring (buffer, a [i + 2], a [i + 3], False) ~ value then
							Result := True
						end
					end
					i := i + Group_size
				end
			end
		end

	last_name (a_buffer: SPECIAL [CHARACTER_8]): STRING
		local
			i: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			if count > 0 and then attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached name_cache as names
			then
				i := (count - 1) * Group_size
				buffer := i_th_name (i, a_buffer, overflow_area)
				Result := name_cache.item (buffer, a [i], a [i + 1])
			else
				Result := Empty_string
			end
		end

	last_value (a_buffer: SPECIAL [CHARACTER_8]): STRING
		local
			i: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			if count > 0 and then attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached name_cache as names
			then
				i := (count - 1) * Group_size
				buffer := i_th_value (i, a_buffer, overflow_area)
				Result := area_substring (buffer, a [i + 2], a [i + 3], False)
			else
				Result := Empty_string
			end
		end

	stop_on_criteria (a_buffer: SPECIAL [CHARACTER_8])
		local
			name, value: STRING
		do
		-- <glob pattern="*.asc" weight="10"/>
			if has_value (a_buffer, once "pattern", once "*.asc")
				and then has_value (a_buffer, once "weight", once "10")
			then
				name := Empty_string; value := Empty_string
			else
				name := last_name (a_buffer); value := last_value (a_buffer)
			end
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
			i, i_final: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			Result := attribute_table
			Result.wipe_out
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area then
				from i := 0; i_final := index_count until i = i_final loop
					buffer := i_th_name (i, a_buffer, overflow_area)
					if attached name_cache.item (buffer, a [i], a [i + 1]) as name then
						buffer := i_th_value (i, a_buffer, overflow_area)
						if attached area_substring (buffer, a [i + 2], a [i + 3], True) as value then
							if attached entity_refs_area [i // Group_size] as entity_list then
								Result.put (entity_table.expanded_value (entity_list, value, True), name)
							else
								Result.put (value.twin, name) -- must make a twin
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

	check_value (name: STRING; default_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE])
		-- if `name' matches some name in `default_values' then check it off
		local
			i: INTEGER; value: XT_DEFAULT_ATTRIBUTE_VALUE
		do
			from i := 0 until i = default_values.count loop
				value := default_values [i]
				if name = value.name then
					value.check_
					i := default_values.count -- break
				else
					i := i + 1
				end
			end
		end

	i_th_name (i: INTEGER; buffer: SPECIAL [CHARACTER_8]; overflow_area: like overflow_buffer_area): SPECIAL [CHARACTER_8]
		-- override `buffer' with `overflow_area [i // 2]' if not Void (consequence of `shift_buffer_left' )
		require
			index_at_start_of_group: i.integer_remainder (Group_size) = 0
		do
			if attached overflow_area [i // 2] as overflow then
				Result := overflow
			else
				Result := buffer
			end
		end

	i_th_value (i: INTEGER; buffer: SPECIAL [CHARACTER_8]; overflow_area: like overflow_buffer_area): SPECIAL [CHARACTER_8]
		-- override `buffer' with `overflow_area [i // 2 + 1]' if not Void (consequence of `shift_buffer_left' )
		require
			index_at_start_of_group: i.integer_remainder (Group_size) = 0
		do
			Result := buffer
			if attached overflow_area [i // 2 + 1] as overflow then
				Result := overflow
			end
		end

feature {NONE} -- Deferred

	to_utf_8 (source, dest: SPECIAL [CHARACTER]; a_from_index, a_from_end: INTEGER)
			-- Convert source[a_from_index..a_from_end) to UTF-8 in dest [a_to_index .. a_to_end).
			-- Sets consumed_from and written_to.
		deferred
		end

	to_utf_16 (source: SPECIAL [CHARACTER]; dest: SPECIAL [NATURAL_16]; a_from_index, a_from_end: INTEGER)
			-- Convert source[a_from_index..a_from_end) to UTF-16 in dest.
			-- Sets consumed_from and written_to.
		deferred
		end


end
