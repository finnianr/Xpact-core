note
	description: "[
		List of indices demarking name-value attribute pair substrings in ${XT_XML_PARSER_BASE}.buffer
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-24 18:13:41 GMT (Friday 24th July 2026)"
	revision: "1"

deferred class
	XT_ATTRIBUTE_INTERVAL_LIST

inherit
	ARRAYED_LIST [INTEGER]
		rename
			empty as empty_list,
			index_of as index_of_item,
			forth as index_forth,
			extend as extend_index,
			count as index_count,
			capacity as index_capacity
		export
			{NONE} all
		undefine
			new_filled_list
		redefine
			make, wipe_out
		end

	XT_STRING_8_ROUTINES_I
		rename
			index_of as index_of_character
		export
			{NONE} all
		undefine
			copy, is_equal
		end

	EL_STRING_H_C_API
		undefine
			copy, is_equal
		end

	XT_STRING_CONSTANTS
		undefine
			copy, is_equal
		end

feature {NONE} -- Initialization

	make (n: INTEGER)
		do
			Precursor (n)
			create character_swap_area.make_filled ('%U', capacity)
			create attribute_table.make (11)
			create name_area.make_empty (capacity)
			create overflow_buffer_area.make_empty (capacity)
			create expat_c_string_array.make_empty (capacity + 1)
			create buffer_pool.make (10)

			create entity_cache.make
			create entity_table.make (37)
			entity_table.set_predefined (entity_cache)
			create name_cache.make
			create xml_attribute.make_filled (name_cache.default_name, Version, Standalone)
			initialize_xml_attributes
		end

feature -- Access

	entity_cache: XT_ENTITY_NAME_CACHE
		-- efficient lookup of entity names from character buffer interval

	entity_table: XT_ENTITY_TABLE
		-- table of expanded entities defined in DOCTYPE by ENTITY

	name_cache: XT_NAME_CACHE
		-- efficient lookup of attribute/tag name

	index_of (name: STRING): INTEGER
		-- index of `name' using comparison by reference
		-- 0 if not found
		require
			name_in_cache: name_cache.attribute_item (name.area, 0, name.count - 1, 0) = name
		local
			i, i_final: INTEGER
		do
			if attached name_area as l_area then
				from i := 0; i_final := l_area.count until i = i_final or Result.to_boolean loop
					if l_area [i] = name then
						Result := i + 1
					else
						i := i + 1
					end
				end
			end
		end

	value_index_of (name: STRING): INTEGER
		-- zero based index into `bucket_area' for value start index associated with attribute `name'
		-- using comparison by reference. `-1' if not found
		require
			name_in_cache: name_cache.attribute_item (name.area, 0, name.count - 1, 0) = name
		local
			name_index: INTEGER
		do
			name_index := index_of (name)
			if name_index.to_boolean then
				Result := (name_index - 1) * 2
			else
				Result := -1
			end
		end

feature -- Measurement

	capacity: INTEGER
		-- count of intervals
		do
			Result := index_capacity // Interval_count
		end

feature -- Basic operations

	check_forward (prefix_name, uri: STRING)
		-- check forward references of new xmlns declaration
		do
			-- does something in `XT_URI_MAPPED_ATTRIBUTE_LIST'
		end

feature -- Constants

	Interval_count: INTEGER = 2
		-- number of array items needed to hold upper and lower index for one attribute value

feature -- Removal

	reset
		do
			name_cache.reset
			initialize_xml_attributes
			wipe_out
		end

	wipe_out
		local
			i, i_final: INTEGER
		do
			index := 0
			if attached overflow_buffer_area as overflow and then attached buffer_pool as pool then
			-- recycle value and entity reference list buffers
				from i := 0; i_final := overflow.count until i = i_final loop
					if attached overflow [i] as buffer then
						pool.return (buffer)
					end
					i := i + 1
				end
				overflow.wipe_out; name_area.wipe_out
			end
			area.wipe_out
		end

feature {NONE} -- Implementation

	empty_c_string_array (minimum_capacity: INTEGER): SPECIAL [POINTER]
		do
			Result := expat_c_string_array
			if Result.capacity < minimum_capacity then
				create Result.make_empty (minimum_capacity)
				expat_c_string_array := Result
			else
				Result.wipe_out
			end
		ensure
			big_enough: Result.capacity >= minimum_capacity
			zero_count: Result.count = 0
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
					check
						comparing_by_reference: not name.is_equal (value.name)
					end
					i := i + 1
				end
			end
		end

	choose (i: INTEGER; a_buffer: SPECIAL [CHARACTER_8]; overflow_area: like overflow_buffer_area): SPECIAL [CHARACTER_8]
		-- `a_buffer' if `overflow_area [i // 2] /= Void' else `overflow_area [i // 2]'
		-- Needed as consequence of possible call to `shift_buffer_left'
		require
			index_at_start_of_group: i.integer_remainder (Interval_count) = 0
		do
			if attached overflow_area [i // 2] as buffer then
				Result := buffer
			else
				Result := a_buffer
			end
		end

	has_duplicate_name (name: like name_area.item; a_name_area: like name_area): BOOLEAN
		local
			i, i_final: INTEGER
		do
			from i := 0; i_final := a_name_area.count until i = i_final or Result loop
				if a_name_area [i] = name then
					Result := True
				else
					check
						comparing_by_reference: not a_name_area [i].is_equal (name)
					end
					i := i + 1
				end
			end
		end

	initialize_xml_attributes
		-- allows attributes to be searched for by reference rather than object comparison
		local
			i: INTEGER
		do
			from i := Version until i > Standalone loop
				if attached {STRING} XML_declaration.reference_item (i + 1) as name then
					xml_attribute [i] := name_cache.attribute_name (name)
				end
				i := i + 1
			end
		ensure
			standalone_last: xml_attribute [Standalone].same_string (Xml_declaration.standalone)
		end

	not_utf_8_encoded (lower_index, upper_index, utf_8_count: INTEGER): BOOLEAN
		-- 'True' if `utf_8_count' implies that buffer from `lower_index' to `upper_index'
		-- is not already valid as UTF-8
		do
			Result := utf_8_count > upper_index - lower_index + 1
		end

	unchecked_count (default_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE]): INTEGER
		-- count of `default_values' that are unchecked
		local
			i: INTEGER
		do
			from i := 0 until i = default_values.count loop
				Result := (not default_values [i].checked).to_integer
				i := i + 1
			end
		end

	uncheck_defaults (default_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE])
		-- mark all defaults as unchecked again
		local
			i: INTEGER
		do
			from i := 0 until i = default_values.count loop
				default_values [i].uncheck
				i := i + 1
			end
		end

feature {NONE} -- Internal attributes

	attribute_table: HASH_TABLE [STRING, STRING]
		-- reuseable table of name-value attribute pairs

	expat_c_string_array: SPECIAL [POINTER]
		-- eXpat compatible C string array with terminating NUL pointer

	character_swap_area: SPECIAL [CHARACTER_8]

	name_area: SPECIAL [STRING]

	overflow_buffer_area: SPECIAL [detachable SPECIAL [CHARACTER_8]]

	buffer_pool: XT_CHARACTER_BUFFER_POOL

	xml_attribute: ARRAY [like name_cache.item]
		-- In order: <?xml version = "1.0" encoding = "UTF-8" standalone = "yes">

feature {NONE} -- Indices for `xml_attribute'

	Version: INTEGER = 1

	Encoding: INTEGER = 2

	Standalone: INTEGER = 3

feature {NONE} -- Constants

	Shared_checksum: SPECIAL [EL_CRC_32_DIGEST]
		once
			create Result.make_filled (create {EL_CRC_32_DIGEST}, 2)
			Result [1] := create {EL_CRC_32_DIGEST}
		end

invariant
	lower_upper_pairs: index_count.integer_remainder (Interval_count) = 0
	valid_name_area_capacity: name_area.capacity = capacity
	valid_character_swap_capacity: character_swap_area.capacity = capacity
	valid_overflow_buffer_capacity: overflow_buffer_area.capacity = capacity
	valid_expat_c_string_array_capacity: expat_c_string_array.capacity > capacity

end
