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
			make, wipe_out
		end

	XT_STRING_ROUTINES_I
		export
			{NONE} all
		undefine
			copy, is_equal
		end

feature -- Initialization

	make (n: INTEGER)
		do
			Precursor (group_size * n)
			create overflow_buffer_area.make_empty (area.capacity // 2)
			create interval_item_buffer.make_empty (group_size)
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
			i: INTEGER
		do
			if attached area as l_area then
				from until i = l_area.count loop
					Result := Result + l_area [i + 1] - l_area [i] + 1
					i := i + 2
				end
			end
		end

	append_to_crc_32 (checksum: EL_CRC_32_DIGEST; a_buffer: SPECIAL [CHARACTER_8])
		local
			i: INTEGER; buffer: SPECIAL [CHARACTER_8]
		do
			if attached area_v2 as l_area and then attached overflow_buffer_area as overflow_area then
				from start until after loop
					i := index + data_offset - 1
					if attached overflow_area [i // 2] as overflow_buffer then
						buffer := overflow_buffer
					else
						buffer := a_buffer
					end
--					value := characters_crc_32 (value, buffer, l_area [i], l_area [i + 1])
					forth
				end
			end
		end

	group_size: INTEGER
		deferred
		end

	item_interval: SPECIAL [INTEGER]
		do
			Result := interval_item_buffer
			Result.copy_data (area_v2, index - 1, 0, group_size)
		end

	item_c_string_8 (buffer: SPECIAL [CHARACTER_8]): C_STRING_8
		local
			i, lower_index: INTEGER; address_ptr: POINTER
		do
			i := index + data_offset - 1
			if attached area_v2 as l_area then
				lower_index := l_area [i]
				address_ptr := i_th_select (buffer, i).item_address (lower_index)
				create Result.make_shared (address_ptr, l_area [i + 1] - lower_index + 1)
			else
				create Result.make_empty
			end
		end

	overflow_buffers_count: INTEGER
		do
			Result := overflow_buffer_area.count
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

	shift_buffer_left (buffer: SPECIAL [CHARACTER_8]; offset: INTEGER)
		-- Slide all live content left by `a_offset' bytes and adjust every index that points into `buffer'.
		local
			i, i_final, lower_index, upper_index, l_count: INTEGER
		do
			if attached overflow_buffer_area as overflow and attached area_v2 as l_area then
				i_final := count * 2
				from i := 0 until i = i_final loop
					lower_index := l_area [i]; upper_index := l_area [i + 1]
					if lower_index - offset < 0 then
						if overflow [i // 2] = Void then
							l_count := upper_index - lower_index + 1
							l_area [i] := 0; l_area [i + 1] := l_count - 1
							overflow [i // 2] := copied_buffer (buffer, i, lower_index, l_count)
						end
					else
					-- still fits in current buffer
						l_area [i] := lower_index - offset; l_area [i + 1] := upper_index - offset
					end
					i := i + 2
				end
			end
		end

	transfer (additions: like interval_item_buffer)
		-- move contents of `additions' into `area'
		require
			full_buffer: additions.count = group_size
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
				on_resize (new_capacity)
			end
			l_area.copy_data (additions, 0, index_count, additions.count)
			if attached overflow_buffer_area as overflow then
				l_count := group_size // 2
				from i := 0 until i = l_count loop
					overflow.extend (Void)
					i := i + 1
				end
			end
			additions.wipe_out
		ensure
			empty_additions_buffer: additions.count = 0
		end

	wipe_out
		local
			i, i_final: INTEGER
		do
			index := 0
			if attached overflow_buffer_area as overflow then
				if not overflow.filled_with (Void, 0, overflow.count - 1) then
					i_final := overflow.count
					from i := 0 until i = i_final loop
						if is_value (i) and then attached overflow [i] as buffer then
							Buffer_pool.return (buffer)
						end
						i := i + 1
					end
				end
				overflow.wipe_out
			end
			area.wipe_out; interval_item_buffer.wipe_out
		end

feature {NONE} -- Implementation

	copied_buffer (buffer: SPECIAL [CHARACTER_8]; i, lower_index, a_count: INTEGER): SPECIAL [CHARACTER_8]
		do
			Result := Buffer_pool.borrow_item (a_count)
			Result.wipe_out
			Result.copy_data (buffer, lower_index, 0, a_count)
		end

	i_th_select (buffer: SPECIAL [CHARACTER_8]; i: INTEGER): SPECIAL [CHARACTER_8]
		-- select between `buffer' and overflow buffer corresponding to `area' index `i'
		do
			if attached overflow_buffer_area [i // 2] as overflow_buffer then
				Result := overflow_buffer
			else
				Result := buffer
			end
		end

	is_value (overflow_index: INTEGER): BOOLEAN
		-- True if `overflow_index' is for l_area value and not l_area name
		do
			Result := True
		end

	data_offset: INTEGER
		-- redefined in `XT_ATTRIBUTE_BUFFER_INTERVALS' to return 2 (skipping the attribute name)
		do
			-- default zero
		end

	on_resize (a_capacity: INTEGER)
		require
			even_number: a_capacity.integer_remainder (2) = 0
		do
			overflow_buffer_area := overflow_buffer_area.aliased_resized_area (a_capacity // 2)
		end

feature {NONE} -- Internal attributes

	interval_item_buffer: SPECIAL [INTEGER]
		-- buffer for single name-value pair interval indices

	overflow_buffer_area: SPECIAL [detachable SPECIAL [CHARACTER_8]]

	Buffer_pool: XT_CHARACTER_BUFFER_POOL
		once
			create Result.make (10)
		end

invariant
	lower_upper_pairs: index_count.integer_remainder (group_size) = 0
	proportional_overflow_buffer_capacity: overflow_buffer_area.capacity = area.capacity // 2
end
