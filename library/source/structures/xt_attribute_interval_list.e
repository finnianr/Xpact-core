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
		export
			{NONE} all
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
			create buffer_pool.make (10)

			create entity_cache.make
			create entity_table.make (37)
			entity_table.set_predefined (entity_cache)
			create name_cache.make
		end

feature -- Access

	entity_cache: XT_ENTITY_NAME_CACHE
		-- efficient lookup of entity names from character buffer interval

	entity_table: XT_ENTITY_TABLE
		-- table of expanded entities defined in DOCTYPE by ENTITY

	name_cache: XT_NAME_CACHE
		-- efficient lookup of attribute/tag name

feature -- Measurement

	capacity: INTEGER
		-- count of intervals
		do
			Result := index_capacity // Interval_count
		end

feature -- Constants

	Interval_count: INTEGER = 2
		-- number of array items needed to hold upper and lower index for one attribute value

feature -- Basic operations

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

feature {NONE} -- Internal attributes

	attribute_table: HASH_TABLE [STRING, STRING]
		-- reuseable table of name-value attribute pairs

	character_swap_area: SPECIAL [CHARACTER_8]

	name_area: SPECIAL [STRING]

	overflow_buffer_area: SPECIAL [detachable SPECIAL [CHARACTER_8]]

	buffer_pool: XT_CHARACTER_BUFFER_POOL

invariant
	lower_upper_pairs: index_count.integer_remainder (Interval_count) = 0
	valid_name_area_capacity: name_area.capacity = capacity
	valid_character_swap_capacity: character_swap_area.capacity = capacity
	valid_overflow_buffer_capacity: overflow_buffer_area.capacity = capacity

end
