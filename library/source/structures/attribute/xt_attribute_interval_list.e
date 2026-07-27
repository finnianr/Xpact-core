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
			forth as index_forth,
			extend as extend_index,
			count as index_count
		export
			{NONE} all
		undefine
			new_filled_list
		redefine
			make, wipe_out
		end

feature -- Initialization

	make (n: INTEGER)
		do
			Precursor (n)
			create character_swap_area.make_filled ('%U', area.capacity // Group_size)
			create attribute_table.make (11)
			create entity_cache.make
			create entity_table.make (entity_cache)
			create entity_refs_pool.make (10)
			create entity_refs_area.make_empty (area.capacity // Group_size)
			create overflow_buffer_area.make_empty (area.capacity // 2)
			create buffer_pool.make (10)
			create name_cache.make
			create utf_8_buffer.make_empty (100)
		end

feature -- Access

	entity_cache: XT_ENTITY_NAME_CACHE
		-- efficient lookup of entity names from character buffer interval

	entity_table: XT_ENTITY_TABLE
		-- table of expanded entities defined in DOCTYPE by ENTITY

	name_cache: XT_NAME_CACHE
		-- efficient lookup of attribute/tag name

feature -- Constants

	Group_size: INTEGER = 4
		-- number of array items needed to hold intervals of one name-value pair

feature -- Basic operations

	wipe_out
		local
			i, j, i_final: INTEGER
		do
			index := 0
			if attached overflow_buffer_area as overflow and then attached entity_refs_area as entity_refs
				and then attached buffer_pool as pool
			then
			-- recycle value and entity reference list buffers
				from i := 1; i_final := overflow.count until i > i_final loop
					if attached overflow [i] as buffer then
						pool.return (buffer)
					end
					j := (i - 1) // 2
					if attached entity_refs [j] as list then
						list.wipe_out
						entity_refs_pool.put (list)
					end
					i := i + 2
				end
				entity_refs.wipe_out; overflow.wipe_out
			end
			area.wipe_out
		end

feature {NONE} -- Internal attributes

	attribute_table: HASH_TABLE [STRING, STRING]
		-- reuseable table of name-value attribute pairs

	character_swap_area: SPECIAL [CHARACTER_8]

	entity_refs_area: SPECIAL [detachable ARRAYED_LIST [STRING]]

	overflow_buffer_area: SPECIAL [detachable SPECIAL [CHARACTER_8]]

	buffer_pool: XT_CHARACTER_BUFFER_POOL

	entity_refs_pool: ARRAYED_STACK [ARRAYED_LIST [STRING]]

	utf_8_buffer: SPECIAL [CHARACTER_8]

invariant
	lower_upper_pairs: index_count.integer_remainder (Group_size) = 0
	proportional_character_swap_capacity: character_swap_area.capacity = area.capacity // Group_size
	proportional_entity_refs_area_capacity: entity_refs_area.capacity = area.capacity // Group_size
	proportional_overflow_buffer_capacity: overflow_buffer_area.capacity = area.capacity // 2

end
