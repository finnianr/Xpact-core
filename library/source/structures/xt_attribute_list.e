note
	description: "[
		List of indices demarking attribute value substrings in ${XT_XML_PARSER_BASE}.buffer
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-22 18:20:41 GMT (Monday 22th June 2026)"
	revision: "1"

class
	XT_ATTRIBUTE_LIST

inherit
	XT_ATTRIBUTE_INTERVAL_LIST

	XT_ENCODING_TYPE_CONSTANTS
		undefine
			copy, is_equal
		end

	XT_PARSE_ERROR_CONSTANTS
		export
			{NONE} all
		undefine
			copy, is_equal
		end

	XT_DATA_TYPES
		export
			{ANY} Type_attribute
		undefine
			copy, is_equal
		end

create
	make

feature -- Status query

	has_value (buffer: SPECIAL [CHARACTER_8]; name, value: STRING): BOOLEAN
		local
			i, i_final: INTEGER
		do
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached  name_area as l_name_area
			then
				from i := 0; i_final := a.count until i = i_final or Result loop
					if l_name_area [i // 2] ~ name then
						if area_substring (choose (i, buffer, overflow_area), a [i], a [i + 1], False) ~ value then
							Result := True
						end
					end
					i := i + Interval_count
				end
			end
		end

	has_valid_encoding (buffer: SPECIAL [CHARACTER_8]): BOOLEAN
		do
			if attached item_value (buffer, xml_attribute [Encoding], False) as l_encoding then
				Result := across to_list (Valid_encoding_list, ',') as valid_encoding some
					l_encoding.is_case_insensitive_equal (valid_encoding)
				end
			else
				Result := True
			end
		end

	standalone_code (a_buffer: SPECIAL [CHARACTER_8]): INTEGER
		local
			i: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			i := value_index_of (xml_attribute [Standalone])
			inspect i when -1 then
				Result := i
			else
				buffer := choose (i, a_buffer, overflow_buffer_area)
				Result := if buffer [area [i]] = 'y' then 1 else 0 end
			end
		end

	standalone_value (buffer: SPECIAL [CHARACTER_8]): STRING
		do
			if attached item_value (buffer, xml_attribute [Standalone], False) as value then
				Result := value
			else
				Result := Valid_yes_no [2]
			end
		end

	is_valid_count: BOOLEAN
		-- `index_count' is multiple of `Interval_count'
		do
			Result := index_count \\ Interval_count = 0
		end

	is_null_terminated: BOOLEAN
		-- `True' if `null_terminate_values' was called

	permit_undefined_entities: BOOLEAN

	swap_area_big_enough: BOOLEAN
		do
			Result := character_swap_area.count >= count
		end

	newline_or_tab_found: BOOLEAN

feature -- Access

	first_name_value_c_array (buffer: SPECIAL [CHARACTER_8]): SPECIAL [POINTER]
		-- eXpat compatible array of first name and value pair as C string pointers
		require
			not_empty: count >= 1
			null_terminated: is_null_terminated
		do
			Result := empty_c_string_array (2)
			if attached area_v2 as a and then a.count > 0 then
				Result.extend (name_area [0].area.base_address)
				Result.extend (choose (0, buffer, overflow_buffer_area).item_address (a [0])) -- value
			end
		ensure
			name_value_pair: Result.count = 2
		end

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
				Result := new_substring (buffer, a [0], a [1])
			else
				Result := Empty_string
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

	last_value (buffer: SPECIAL [CHARACTER_8]): STRING
		local
			i: INTEGER
		do
			if attached area_v2 as a and then a.count > 0 and then attached overflow_buffer_area as overflow_area then
				i := a.count - Interval_count
				Result := area_substring (choose (i, buffer, overflow_area), a [i], a [i + 1], False)
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
					str_area [i // 2] := choose (i, buffer, overflow_buffer_area) [upper_plus_1]
					i := i + Interval_count
				end
			end
		end

	item_value (buffer: SPECIAL [CHARACTER_8]; name: STRING; keep_ref: BOOLEAN): detachable STRING
		-- value associated with attribute `name' using comparison by reference
		-- `Void' if not found
		require
			name_in_cache: name_cache.item (name.area, 0, name.count - 1, 0) = name
		local
			i: INTEGER
		do
			i := value_index_of (name)
			if i > -1 and then attached area_v2 as a then
				Result := area_substring (choose (i, buffer, overflow_buffer_area), a [i], a [i + 1], False)
				if keep_ref then
					Result := Result.twin
				end
			end
		end

feature -- Conversion

	as_table (buffer: SPECIAL [CHARACTER_8]; keep_ref: BOOLEAN): like attribute_table
		-- convert all values to hash table keyed by names
		require
			valid_attributes_count: is_valid_count
		local
			i, i_final: INTEGER
		do
			Result := attribute_table
			Result.wipe_out
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached name_area as l_name_area
			then
				from i := 0; i_final := a.count until i = i_final loop
					if attached area_substring (choose (i, buffer, overflow_area), a [i], a [i + 1], True) as value then
						Result.put (value.twin, l_name_area [i // 2]) -- must make a twin
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

	to_c_array (buffer: SPECIAL [CHARACTER_8]; default_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE]): SPECIAL [POINTER]
		-- eXpat compatible list of alternating name and value C string pointers terminated by NULL pointer
		require
			null_terminated: is_null_terminated
		local
			i, i_final, c_array_capacity: INTEGER; name: STRING; attribute_: XT_DEFAULT_ATTRIBUTE_VALUE
		do
			Result := expat_c_string_array
			Result.wipe_out

			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached name_area as l_name_area and then attached buffer_pool as pool
			then
				from i := 0; i_final := a.count until i = i_final loop
					name := l_name_area [i // 2]
					if default_values.count > 0 then
						check_value (name, default_values)
					end
					Result.extend (name.area.base_address)
					Result.extend (choose (i, buffer, overflow_area).item_address (a [0])) -- value
					i := i + Interval_count
				end
				c_array_capacity := a.count + 1
			-- Add default values for unchecked
				from i := 0 until i = default_values.count loop
					attribute_ := default_values [i]
					if not attribute_.checked then
						c_array_capacity := c_array_capacity + 2
					-- ensure enough capacity
						if Result.capacity < c_array_capacity then
							Result := Result.aliased_resized_area (c_array_capacity)
							expat_c_string_array := Result
						end
						Result.extend (attribute_.name.area.base_address)
						Result.extend (attribute_.value.area.base_address)
					end
					i := i + 1
				end
				Result.extend (default_pointer)
			end
		ensure
			filled: Result.count >= (count + unchecked_count (default_values)) * 2 + 1
			checksums_agree: checksums_agree (buffer, default_values, Result)
		end

	to_version_encoding_c_array (buffer: SPECIAL [CHARACTER_8]): SPECIAL [POINTER]
		-- eXpat compatible array of XML declaration version and encoding value as C string pointers
		require
			not_empty: count >= 1
			null_terminated: is_null_terminated
		local
			i, j: INTEGER
		do
			Result := empty_c_string_array (2)
			Result.fill_with (default_pointer, 0, 1)
			if attached overflow_buffer_area as overflow and then attached area_v2 as a then
				from i := Version until i > Encoding loop
					j := value_index_of (xml_attribute [i])
					inspect j when -1 then
						do_nothing
					else
						Result [i] := choose (j, buffer, overflow).item_address (a [j])
					end
					i := i + 1
				end
			end
		ensure
			name_value_pair: Result.count = 2
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

	set_permit_undefined_entities (yes: BOOLEAN)
		do
			permit_undefined_entities := yes
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

feature -- Appending to CRC-32 checksum

	append_first_value_to_crc_32 (buffer: SPECIAL [CHARACTER_8]; checksum: EL_CRC_32_DIGEST)
		require
			not_empty: count > 0
		do
			if attached area_v2 as a then
				checksum.add_characters (choose (0, buffer, overflow_buffer_area), a [0], a [1])
			end
		end

	append_to_crc_32 (
		buffer: SPECIAL [CHARACTER_8]; default_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE]
		checksum: EL_CRC_32_DIGEST
	)
		require
			all_default_values_unchecked: across default_values as value all not value.checked end
		local
			i, i_final, lower_index, upper_index: INTEGER; attribute_: XT_DEFAULT_ATTRIBUTE_VALUE
			name: STRING
		do
			if attached area_v2 as a and then attached overflow_buffer_area as overflow_area
				and then attached name_area as l_name_area
			then
				from i := 0; i_final := a.count until i = i_final loop
					name := l_name_area [i // 2]
					if default_values.count > 0 then
						check_value (name, default_values)
					end
					lower_index := a [i]; upper_index := a [i + 1]
					checksum.add_string (name)
					checksum.add_characters (choose (i, buffer, overflow_area), lower_index, upper_index)
					i := i + Interval_count
				end
			-- Add default values for unchecked
				from i := 0 until i = default_values.count loop
					attribute_ := default_values [i]
					if not attribute_.checked then
						checksum.add_string (attribute_.name)
						checksum.add_string (attribute_.value)
					end
					i := i + 1
				end
			end
		end

	append_xml_declaration_to_crc_32 (a_buffer: SPECIAL [CHARACTER_8]; checksum: EL_CRC_32_DIGEST)
		local
			i, j: INTEGER
		do
		-- iterate over encoding, standalone, version
			if attached overflow_buffer_area as overflow and then attached area_v2 as a then
				from i := Version until i > Encoding loop
					j := value_index_of (xml_attribute [i])
					if j > -1 then
						checksum.add_characters (choose (j, a_buffer, overflow), a [j], a [j + 1])
					end
					i := i + 1
				end
			end
			checksum.add_integer_32 (standalone_code (a_buffer))
		end

feature -- Basic operations

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
							l_buffer.extend ('%U')
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

	transfer (
		buffer: SPECIAL [CHARACTER_8]; additions: like area; colon_index: INTEGER; entity_list: ARRAYED_LIST [XT_ENTITY_NAME]
	): INTEGER
		-- transfer contents of `additions' into `area' and contents of `entity_list'
		-- into `entity_refs_area'
		require
			valid_colon_index: colon_index.to_boolean implies additions [0] < colon_index and then colon_index <  additions [1]
			full_buffer: additions.count = Interval_count * 2
			valid_intervals: valid_intervals (additions)
		local
			i, new_capacity, value_count, l_capacity: INTEGER; l_area: like area_v2; overflow: like overflow_buffer_area
			l_name_area: like name_area; expanded_value, name: STRING
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
				l_capacity := new_capacity // Interval_count
				overflow := overflow.aliased_resized_area (l_capacity)
				overflow_buffer_area := overflow
				l_name_area := l_name_area.aliased_resized_area (l_capacity)
				name_area := l_name_area
				character_swap_area := character_swap_area.aliased_resized_area_with_default ('%U', l_capacity)
				if expat_c_string_array.capacity < l_capacity + 1 then
					create expat_c_string_array.make_empty (l_capacity + 1)
				end
			end
			if newline_or_tab_found then
			-- XML §3.3.3 attribute-value normalisation: replace %N %T with space
				normalize_whitespace (buffer, additions [2], additions [3])
				newline_or_tab_found := False
			end
			name := name_cache.item (buffer, additions [0], additions [1], colon_index)
			if has_duplicate_name (name, l_name_area) then
				Result := Error_duplicate_attribute
			else
				l_name_area.extend (name)
				if entity_list.count > 0 then
					expanded_value := entity_table.expanded_value (buffer, additions [2], additions [3], entity_list.area, False, False)
					value_count := expanded_value.count

					if entity_table.undefined_entity_found and then not permit_undefined_entities then
						Result := Error_undefined_entity
					else
						if attached buffer_pool.borrow_item (value_count) as l_buffer
							and then attached expanded_value.area as value_area
						then
							l_buffer.wipe_out
							l_buffer.copy_data (value_area, 0, 0, value_count + 1) -- include '%U' terminator
							overflow.extend (l_buffer)
							additions [2] := 0; additions [3] := value_count - 1
						end
					end
				else
					overflow.extend (Void)
				end
				l_area.copy_data (additions, 2, l_area.count, Interval_count)
			end
			additions.wipe_out; entity_list.wipe_out
		ensure
			all_valid: all_valid
			empty_additions_buffer: additions.count = 0
			empty_entity_list_buffer: entity_list.count = 0
			newline_or_tab_reset: not newline_or_tab_found
		end

feature -- Debug helpers

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

	checksums_agree (
		buffer: SPECIAL [CHARACTER_8]; default_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE]; c_array: SPECIAL [POINTER]
	): BOOLEAN
		-- `True' if checksum from `append_to_crc_32' agrees with checksum calculated on `c_array'
		-- which are the attribute arguments for C handler `startElementHandler' defined
		-- in struct XML_ParserStruct
		local
			checksum_1, checksum_2: EL_CRC_32_DIGEST; i: INTEGER
		do
			checksum_1 := Shared_checksum [0]; checksum_1.reset
			uncheck_defaults (default_values); append_to_crc_32 (buffer, default_values, checksum_1)

			checksum_2 := Shared_checksum [1]; checksum_2.reset
			from i := 0 until i > c_array.count or else c_array [i].is_default_pointer loop
				checksum_2.add_bytes (c_array [i], c_string_8_length (c_array [i]))
				checksum_2.add_bytes (c_array [i + 1], c_string_8_length (c_array [i + 1]))
				i := i + 2
			end
			Result := checksum_1.value = checksum_2.value
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

feature {NONE} -- Implementation

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (n)
		end

end
