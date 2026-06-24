note
	description: "List of indices demarking name and attribute value string in {XPACT_INCREMENTAL_PARSER}.buffer"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-22 18:20:41 GMT (Monday 22th June 2026)"
	revision: "1"
class
	XT_STRING_INTERVALS

inherit
	ARRAYED_LIST [INTEGER]
		rename
			make as make_sized,
			extend as extend_index
		export
			{NONE} all
		redefine
			wipe_out
		end

create
	make

feature -- Initialization

	make (n, buffer_size: INTEGER)
		do
			make_sized (n)
			create additions_buffer.make_empty (buffer_size)
		end

feature -- Measurement

	count_sum: INTEGER
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

feature -- Access

	additions_buffer: SPECIAL [INTEGER]
		-- buffer for single name-value pair interval indices

feature -- Basic operations

	extend (lower_index, upper_index: INTEGER)
		local
			i: INTEGER; l_area: like area_v2
		do
			i := count + 2
			l_area := area_v2
			if i > l_area.capacity then
				l_area := l_area.aliased_resized_area (i + additional_space)
				area_v2 := l_area
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
				i := count + additions.count
				l_area := area_v2
				if i > l_area.capacity then
					l_area := l_area.aliased_resized_area (i + additional_space)
					area_v2 := l_area
				end
				l_area.copy_data (additions, 0, count, additions.count)
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

invariant
	lower_upper_pairs: count \\ 2 = 0
end