note
	description: "List of character/string buffers in ascending order of capacity"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-17 18:04:00 GMT (Thursday 17th September 2026)"
	revision: "1"

deferred class
	XT_SORTED_BUFFER_POOL [G]

inherit
	ARRAYED_LIST [G]
		export
			{NONE} all
			{ANY} count
		undefine
			new_filled_list
		end

feature -- Contract support

	is_sorted_ascending: BOOLEAN
		-- `True' if items sorted in order of size
		local
			i, i_final: INTEGER; previous: like item
		do
			previous := Empty_buffer
			if attached area_v2 as l_area then
				i_final := l_area.count
				Result := True
				from i := 0 until i = i_final or not Result loop
					if capacity_of (l_area [i]) >= capacity_of (previous) then
						previous := l_area [i]
						i := i + 1
					else
						Result := False
					end
				end
			end
		end

feature -- Element change

	borrow_item (size: INTEGER): like item
		local
			i, i_final, l_size: INTEGER; found: BOOLEAN
		do
			l_size := size_plus (size)
			Result := empty_buffer
			if attached area_v2 as l_area then
				i_final := l_area.count
				from i := 0 until i = i_final or found loop
					if capacity_of (l_area [i]) >= l_size then
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
					Result := new_buffer (l_size)
				end
			end
		ensure
			not_default: Result /= Empty_buffer
			big_enough: capacity_of (Result) >= size_plus (size)
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
				if capacity_of (buffer) < capacity_of (l_area [i]) then
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

feature {NONE} -- deferred

	capacity_of (buffer: like item): INTEGER
		deferred
		end

	empty_buffer: like item
		deferred
		end

	new_buffer (size: INTEGER): like item
		deferred
		end

	size_plus (size: INTEGER): INTEGER
		deferred
		end

end
