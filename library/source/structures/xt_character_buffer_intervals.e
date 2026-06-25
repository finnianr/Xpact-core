note
	description: "List of indices demarking substrings in ${XT_XML_PARSER}.buffer"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-22 18:20:41 GMT (Monday 22th June 2026)"
	revision: "1"

deferred class
	XT_CHARACTER_BUFFER_INTERVALS

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
			make, wipe_out, index_count
		end

feature -- Initialization

	make (n: INTEGER)
		do
			Precursor (Group_size * n)
			create additions_buffer.make_empty (Group_size)
		end

feature -- Measurement

	count: INTEGER
		-- count of interval groups
		do
			Result := index_count // Group_size
		end

	index_count: INTEGER
		do
			Result := Precursor
		end

	interval_item: SPECIAL [INTEGER]
		do
			Result := additions_buffer
			Result.copy_data (area_v2, index - 1, 0, group_size)
		end

	character_count: INTEGER
		-- sum of all substring interval counts
		local
			i: INTEGER
		do
			if attached area as a then
				from until i = a.count loop
					Result := Result + a [i + 1] - a [i] + 1
					i := i + 2
				end
			end
		end

feature -- Status query

	is_valid_count: BOOLEAN
		-- `index_count' is multiple of `group_size'
		do
			Result := index_count \\ group_size = 0
		end

feature -- Cursor movement

	forth
			-- Move cursor to first position if any.
		do
			index := index + group_size
		end

feature -- Access

	additions_buffer: SPECIAL [INTEGER]
		-- buffer for single name-value pair interval indices

feature -- Basic operations

	extend (lower_index, upper_index: INTEGER)
		local
			i: INTEGER; l_area: like area_v2
		do
			i := index_count + 2
			l_area := area_v2
			if i > l_area.capacity then
				l_area := l_area.aliased_resized_area (i + additional_space)
				area_v2 := l_area
				on_resize
			end
			l_area.extend (lower_index); l_area.extend (upper_index)
		end

	update
		-- update list with contents of `additions_buffer'
		require
			full_buffer: additions_buffer.count = additions_buffer.capacity
		local
			i: INTEGER; l_area: like area_v2
		do
			if attached additions_buffer as additions then
				i := index_count + additions.count
				l_area := area_v2
				if i > l_area.capacity then
					l_area := l_area.aliased_resized_area (i + additional_space)
					area_v2 := l_area
					on_resize
				end
				l_area.copy_data (additions, 0, index_count, additions.count)
				additions.wipe_out
			end
		ensure
			empty_additions_buffer: additions_buffer.count = 0
		end

	wipe_out
		do
			index := 0
			area.wipe_out; additions_buffer.wipe_out
		end

feature {NONE} -- Implementation

	group_size: INTEGER
		deferred
		end

	on_resize
		do
		end

invariant
	lower_upper_pairs: index_count \\ 2 = 0
end
