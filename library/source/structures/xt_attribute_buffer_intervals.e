note
	description: "[
		List of indices demarking name-value attribute pair substrings in ${XT_XML_PARSER}.buffer
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-22 18:20:41 GMT (Monday 22th June 2026)"
	revision: "1"
class
	XT_ATTRIBUTE_BUFFER_INTERVALS

inherit
	XT_CHARACTER_BUFFER_INTERVALS
		redefine
			make, on_resize
		end

create
	make

feature -- Initialization

	make (n: INTEGER)
		do
			Precursor (n)
			create character_swap_area.make_empty (n)
		end

feature -- Status query

	swap_area_big_enough: BOOLEAN
		do
			Result := character_swap_area.capacity >= count
		end

	upper_plus_1_characters (buffer: SPECIAL [CHARACTER_8]): STRING
		require
			swap_area_big_enough: swap_area_big_enough
		local
			i, j, i_final, upper_plus_1: INTEGER
		do
			create Result.make_filled ('%U', count)
			if attached area_v2 as l_area and then attached Result.area as str_area then
				i_final := count * Group_size
				from i := 0 until i = i_final loop
					upper_plus_1 := l_area [i + 3] + 1
					str_area [j] := buffer [upper_plus_1]
					i := i + Group_size; j := j + 1
				end
			end
		end

feature -- Status change

	null_terminate_values (buffer: SPECIAL [CHARACTER_8])
		require
			swap_area_big_enough: swap_area_big_enough
		local
			i, i_final, upper_plus_1: INTEGER
		do
			if attached character_swap_area as swap_area and attached area_v2 as l_area then
				swap_area.wipe_out
				i_final := count * Group_size
				from i := 0 until i = i_final loop
					upper_plus_1 := l_area [i + 3] + 1
					swap_area.extend (buffer [upper_plus_1])
					buffer [upper_plus_1] := '%U'
					i := i + Group_size
				end
			end
		end

	undo_null_terminated_values (buffer: SPECIAL [CHARACTER_8])
		require
			swap_area_big_enough: swap_area_big_enough
		local
			i, j, i_final, upper_plus_1: INTEGER
		do
			if attached character_swap_area as swap_area and attached area_v2 as l_area then
				i_final := count * Group_size
				from i := 0; j := 0 until i = i_final loop
					upper_plus_1 := l_area [i + 3] + 1
					buffer [upper_plus_1] := swap_area [j]
					i := i + Group_size; j := j + 1
				end
			end
		end

feature {NONE} -- Implementation

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (n)
		end

	on_resize
		do
			character_swap_area := character_swap_area.aliased_resized_area (area_v2.capacity // Group_size)
		end

feature {NONE} -- Internal attributes

	character_swap_area: SPECIAL [CHARACTER_8]

feature {NONE} -- Constants

	Group_size: INTEGER = 4

end
