note
	description: "Pool of reusable buffers"
	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-06-28 6:31:14 GMT (Sunday 28th June 2026)"
	revision: "1"

class
	XT_CHARACTER_BUFFER_POOL

inherit
	ARRAYED_LIST [SPECIAL [CHARACTER_8]]
		export
			{NONE} all
			{ANY} count
		end

create
	make

feature -- Status report

	is_sorted_ascending: BOOLEAN
		-- `True' if items sorted in order of size
		local
			i, i_final: INTEGER; previous: like item
		do
			previous := Default_buffer
			if attached area_v2 as l_area then
				i_final := l_area.count
				Result := True
				from i := 0 until i = i_final or not Result loop
					if l_area [i].capacity >= previous.capacity then
						previous := l_area [i]
						i := i + 1
					else
						Result := False
					end
				end
			end
		end

feature -- Access

	borrow_item (size: INTEGER): like item
		local
			i, i_final, size_plus: INTEGER; found: BOOLEAN
		do
			size_plus := size + 1 -- include 1 extra for possible null termination
			Result := Default_buffer
			if attached area_v2 as l_area then
				i_final := l_area.count
				from i := 0 until i = i_final or found loop
					if l_area [i].capacity >= size then
						Result := l_area [i]
						found := True
					else
						i := i + 1
					end
				end
				if found then
				-- remove borrowed from list
					l_area.move_data (i + 1, i, l_area.count - i - 1)
					l_area.remove_tail (1)

				else
					create Result.make_empty (size_plus)
				end
			end
		ensure
			not_default: Result /= Default_buffer
			ascending_order: is_sorted_ascending
		end

	return (buffer: like item)
		-- return borrowed item inserting at position to ensure ascending order
		local
			i, i_final: INTEGER; found: BOOLEAN; l_area: like area
		do
			l_area := area_v2
			i := l_area.count + 1
			if i > l_area.capacity then
				l_area := l_area.aliased_resized_area (i + additional_space)
				area_v2 := l_area
			end
			i_final := l_area.count
			from i := 0 until i = i_final or found loop
				if buffer.capacity < l_area [i].capacity then
					found := True
				else
					i := i + 1
				end
			end
			if found then
			-- insert at i'th position moving remaining to right
				l_area.move_data (i, i + 1, count - i)
				l_area [i] := buffer
			else
				l_area.extend (buffer)
			end
		ensure
			ascending_order: is_sorted_ascending
		end

feature {NONE} -- Constants

	Default_buffer: SPECIAL [CHARACTER_8]
		once
			create Result.make_empty (0)
		end

end
