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

	STRING_HANDLER
		undefine
			copy, is_equal
		end

feature -- Initialization

	make (n: INTEGER)
		do
			Precursor (Group_size * n)
			create interval_item_buffer.make_empty (Group_size)
		end

feature -- Measurement

	count: INTEGER
		-- count of interval groups
		do
			Result := index_count // Group_size
		end

	group_size: INTEGER
		deferred
		end

	index_count: INTEGER
		do
			Result := Precursor
		end

	item_interval: SPECIAL [INTEGER]
		do
			Result := interval_item_buffer
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

feature -- Basic operations

	append_to (buffer: SPECIAL [CHARACTER_8]; str: STRING)
		local
			i, j, lower_index, upper_index: INTEGER; c_i: CHARACTER; first_copied: BOOLEAN
		do
			str.grow (character_count)
			if attached str.area as area_out then
				from j := 0 start until after loop
					if attached item_interval as array then
						upper_index := array [1]
						from i := array [0] until i > upper_index loop
							c_i := buffer [i]
							if not first_copied then
								first_copied := not c_i.is_space
							end
							if first_copied then
								area_out [j] := c_i
								j := j + 1
							end
							i := i + 1
						end
					end
					forth
				end
				str.set_count (j)
			end
		end

	transfer (additions: like interval_item_buffer)
		-- move contents of `additions' into `area'
		require
			full_buffer: additions.count = group_size
		local
			i: INTEGER; l_area: like area_v2
		do
			i := index_count + additions.count
			l_area := area_v2
			if i > l_area.capacity then
				l_area := l_area.aliased_resized_area (i + additional_space)
				area_v2 := l_area
				on_resize
			end
			l_area.copy_data (additions, 0, index_count, additions.count)
			additions.wipe_out
		ensure
			empty_additions_buffer: additions.count = 0
		end

	wipe_out
		do
			index := 0
			area.wipe_out; interval_item_buffer.wipe_out
		end

feature {NONE} -- Implementation

	on_resize
		do
		end

feature {NONE} -- Internal attributes

	interval_item_buffer: SPECIAL [INTEGER]
		-- buffer for single name-value pair interval indices

invariant
	lower_upper_pairs: index_count \\ 2 = 0
end
