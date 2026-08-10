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

class
	XT_ATTRIBUTE_BUFFER_INTERVALS

inherit
	XT_ATTRIBUTE_INTERVAL_LIST

	XT_ENCODING_TYPE_CONSTANTS
		undefine
			copy, is_equal
		end

create
	make

feature -- Status query

	has_valid_encoding (buffer: SPECIAL [CHARACTER_8]): BOOLEAN
		do
			if attached item_value (buffer, Encoding_attribute, False) as encoding then
				Result := across to_list (Valid_encoding_list, ',') as valid_encoding some
					encoding.is_case_insensitive_equal (valid_encoding)
				end
			else
				Result := True
			end
		end

	is_valid_count: BOOLEAN
		-- `index_count' is multiple of `Interval_count'
		do
			Result := index_count \\ Interval_count = 0
		end

	is_null_terminated: BOOLEAN
		-- `True' if `null_terminate_values' was called

	swap_area_big_enough: BOOLEAN
		do
			Result := character_swap_area.count >= count
		end

	newline_or_tab_found: BOOLEAN

feature -- Access

	first_name: STRING
		require
			not_empty: count > 0
		do
			if attached name_area as l_name_area and then l_name_area.count > 0 then
				Result := l_name_area [0]
			else
				Result := Empty_string
			end
		end

	first_value (buffer: SPECIAL [CHARACTER_8]): STRING
		require
			not_empty: count > 0
		do
			if attached area_v2 as a and then a.count >= Interval_count then
				Result := new_substring (buffer, a [2], a [3])
			else
				Result := Empty_string
			end
		end

	upper_plus_1_characters (buffer: SPECIAL [CHARACTER_8]): STRING
		require
			swap_area_big_enough: swap_area_big_enough
		local
			i, i_final, upper_plus_1: INTEGER
		do
			create Result.make_filled ('%U', count)
			if attached area_v2 as a and then attached Result.area as str_area then
				from i := 0; i_final := a.count until i = i_final loop
					upper_plus_1 := a [i + 1] + 1
					str_area [i // 2] := i_th_value (i, buffer, overflow_buffer_area) [upper_plus_1]
					i := i + Interval_count
				end
			end
		end

	item_value (a_buffer: SPECIAL [CHARACTER_8]; name: STRING; keep_ref: BOOLEAN): detachable STRING
		local
			i, i_final: INTEGER; buffer: SPECIAL [CHARACTER_8]; found: BOOLEAN
		do
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached name_area as l_name_area
			then
				from i := 0; i_final := a.count until i = i_final or found loop
					if l_name_area [i // 2] ~ name then
						buffer := i_th_value (i, a_buffer, overflow_area)
						Result := area_substring (buffer, a [i], a [i + 1], False)
						if keep_ref then
							Result := Result.twin
						end
						found := True
					else
						i := i + Interval_count
					end
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
			if attached character_swap_area as swap_area and attached area_v2 as a
				and then attached overflow_buffer_area as overflow_area
			then
				from i := 0; i_final := a.count until i = i_final loop
					upper_plus_1 := a [i + 1] + 1
					if attached overflow_area [i // 2] as overflow then
						overflow [upper_plus_1] := '%U'
					else
						swap_area [i // 2] := a_buffer [upper_plus_1] -- store current value in swap area
						a_buffer [upper_plus_1] := '%U'
					end
					i := i + Interval_count
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
			if attached character_swap_area as swap_area and attached area_v2 as a then
				from i := 0; i_final := a.count until i = i_final loop
					j := i // 2
					inspect swap_area [j]
						when '%U' then
							do_nothing
					else
						buffer [a [i + 1] + 1] := swap_area [j] -- restore original value
						swap_area [j] := '%U'
					end
					i := i + Interval_count
				end
			end
			is_null_terminated := False
		ensure
			character_swap_area_in_default_state: character_swap_area.filled_with ('%U', 0, count - 1)
		end

	report_newline_or_tab
		-- report the presence of LF OR tab characters in next attribute name/value pair
		-- to be transfered (XML §3.3.3 attribute-value normalisation: replace %N %T with space)
		do
			newline_or_tab_found := True
		end

feature -- Measurement

	count: INTEGER
		-- count of intervals
		do
			Result := index_count // Interval_count
		end

	character_count: INTEGER
		-- sum of all name-value pair counts
		local
			i, i_final: INTEGER
		do
			if attached area as a and then attached name_area as l_name_area then
				from i := 0; i_final := a.count until i = i_final loop
					Result := Result + (a [i + 1] - a [i] + 1) + l_name_area [i // 2].count
					i := i + 2
				end
			end
		end

feature -- Basic operations

	append_first_value_to_crc_32 (checksum: EL_CRC_32_DIGEST; a_buffer: SPECIAL [CHARACTER_8])
		require
			not_empty: count > 0
		local
			buffer: SPECIAL [CHARACTER_8]
		do
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area then
				buffer := i_th_value (0, a_buffer, overflow_area)
				checksum.add_characters (buffer, a [0], a [1])
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
			i, i_final: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached name_area as l_name_area and then attached buffer_pool as pool
			then
				from i := 0; i_final := a.count until i = i_final loop
					c_string_array.extend (l_name_area [i // 2].area.base_address)
					buffer := i_th_value (i, a_buffer, overflow_area)
					c_string_array.extend (buffer.item_address (a [0])) -- value
					i := i + Interval_count
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
			i, i_final, lower_index, upper_index: INTEGER; buffer: SPECIAL [CHARACTER_8]
			attribute_: XT_DEFAULT_ATTRIBUTE_VALUE
		do
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached entity_refs_area as entity_refs and then attached entity_table as table
				and then attached name_area as l_name_area
			then
				from i := 0; i_final := a.count until i = i_final loop
					if default_values.count > 0 then
						check_value (l_name_area [i // 2], default_values)
					end
					buffer := i_th_value (i, a_buffer, overflow_area)

					lower_index := a [i]; upper_index := a [i + 1]
					if attached entity_refs [i // Interval_count] as entity_list then
						table.mix_in_values_to_crc_32 (checksum, buffer, entity_list, lower_index, upper_index)
					else
						checksum.add_characters (buffer, lower_index, upper_index)
					end
					i := i + Interval_count
				end
			-- Add default values for unchecked
				from i := 0 until i = default_values.count loop
					attribute_ := default_values [i]
					if not attribute_.checked then
						checksum.add_string (attribute_.value)
					end
					i := i + 1
				end
			end
		end

	shift_buffer_left (buffer: SPECIAL [CHARACTER_8]; offset: INTEGER)
		-- Slide all live content left by `a_offset' bytes and adjust every index that points into `buffer'.
		local
			i, i_final, shifted_lower_index, lower_index, upper_index, l_count: INTEGER
		do
--			io.put_string ("shift_buffer_left"); io.put_new_line
			if attached overflow_buffer_area as overflow and attached area_v2 as a
				and then attached buffer_pool as pool
			then
			-- iterate over each name and value interval
				from i := 0; i_final := a.count until i = i_final loop
					lower_index := a [i]; upper_index := a [i + 1]
					shifted_lower_index := lower_index - offset
					if shifted_lower_index < 0 then
					-- no longer fits in `buffer' so make a temporary copy to use instead
						l_count := upper_index - lower_index + 1
						a [i] := 0; a [i + 1] := l_count - 1
						if attached pool.borrow_item (l_count) as l_buffer then
							l_buffer.wipe_out
							l_buffer.copy_data (buffer, lower_index, 0, l_count)
							overflow [i // 2] := l_buffer
						end
					else
					-- still fits in current `buffer`
						a [i] := shifted_lower_index; a [i + 1] := upper_index - offset
					end
					i := i + 2
				end
			end
		ensure
			all_valid: all_valid
		end

	transfer (buffer: SPECIAL [CHARACTER_8]; additions: like area; entity_list: ARRAYED_LIST [STRING])
		-- transfer contents of `additions' into `area' and contents of `entity_list'
		-- into `entity_refs_area'
		require
			full_buffer: additions.count = Interval_count * 2
			valid_intervals: valid_intervals (additions)
		local
			i, new_capacity: INTEGER; l_area: like area_v2; overflow: like overflow_buffer_area
			l_name_area: like name_area; name: STRING
		do
			l_area := area_v2; overflow := overflow_buffer_area; l_name_area := name_area
			i := l_area.count + Interval_count
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
				overflow := overflow.aliased_resized_area (new_capacity // Interval_count)
				overflow_buffer_area := overflow
				l_name_area := l_name_area.aliased_resized_area (new_capacity // Interval_count)
				name_area := l_name_area
				entity_refs_area := entity_refs_area.aliased_resized_area (new_capacity // Interval_count)
				character_swap_area := character_swap_area.aliased_resized_area_with_default ('%U', new_capacity // Interval_count)
			end
			if newline_or_tab_found then
			-- XML §3.3.3 attribute-value normalisation: replace %N %T with space
				normalize_whitespace (buffer, additions [2], additions [3])
				newline_or_tab_found := False
			end
			name := name_cache.item (buffer, additions [0], additions [1])
			check_for_duplicate_name (name, l_name_area)
			l_name_area.extend (name)
			l_area.copy_data (additions, 2, l_area.count, Interval_count)
			overflow.extend (Void)

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
			all_valid: all_valid
			empty_additions_buffer: additions.count = 0
			empty_entity_list_buffer: entity_list.count = 0
			cr_lf_tab_reset: not newline_or_tab_found
		end

feature -- Debug helpers

	has_value (a_buffer: SPECIAL [CHARACTER_8]; name, value: STRING): BOOLEAN
		local
			i, i_final: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached  name_area as l_name_area
			then
				from i := 0; i_final := a.count until i = i_final or Result loop
					if l_name_area [i // 2] ~ name then
						buffer := i_th_value (i, a_buffer, overflow_area)
						if area_substring (buffer, a [i], a [i + 1], False) ~ value then
							Result := True
						end
					end
					i := i + Interval_count
				end
			end
		end

	last_name: STRING
		do
			if attached name_area as a and then a.count > 0 then
				Result := a [a.count - 1]
			else
				Result := Empty_string
			end
		end

	last_value (a_buffer: SPECIAL [CHARACTER_8]): STRING
		local
			i: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			if attached area_v2 as a and then a.count > 0 and then attached overflow_buffer_area as overflow_area then
				i := a.count - Interval_count
				buffer := i_th_value (i, a_buffer, overflow_area)
				Result := area_substring (buffer, a [i], a [i + 1], False)
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
				name := last_name; value := last_value (a_buffer)
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
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached name_area as l_name_area
			then
				from i := 0; i_final := a.count until i = i_final loop
					buffer := i_th_value (i, a_buffer, overflow_area)
					if attached area_substring (buffer, a [i], a [i + 1], True) as value then
						if attached entity_refs_area [i // Interval_count] as entity_list then
							Result.put (entity_table.expanded_value (entity_list, value, True), l_name_area [i // 2])
						else
							Result.put (value.twin, l_name_area [i // 2]) -- must make a twin
						end
					end
					check
						not_duplicate_name: Result.inserted
					end
					i := i + Interval_count
				end
			end
			if keep_ref then
				Result := Result.twin
			end
		ensure
			keep_ref_definition: keep_ref implies Result /= attribute_table
		end

feature {NONE} -- Implementation

	check_for_duplicate_name (name: STRING; a_name_area: like name_area)
		local
			i, i_final: INTEGER
		do
			from i := 0; i_final := a_name_area.count until i = i_final loop
				if a_name_area [i] = name then
					has_duplicate_name := True
				end
				i := i + 1
			end
		end

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

	i_th_value (i: INTEGER; a_buffer: SPECIAL [CHARACTER_8]; overflow_area: like overflow_buffer_area): SPECIAL [CHARACTER_8]
		-- override `buffer' with `overflow_area [i // 2]' if not Void (consequence of `shift_buffer_left' )
		require
			index_at_start_of_group: i.integer_remainder (Interval_count) = 0
		do
			if attached overflow_area [i // 2] as buffer then
				Result := buffer
			else
				Result := a_buffer
			end
		end

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (n)
		end

	not_utf_8_encoded (lower_index, upper_index, utf_8_count: INTEGER): BOOLEAN
		-- 'True' if `utf_8_count' implies that buffer from `lower_index' to `upper_index'
		-- is not already valid as UTF-8
		do
			Result := utf_8_count > upper_index - lower_index + 1
		end

end
