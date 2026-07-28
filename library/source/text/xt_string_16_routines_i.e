note
	description: "${XT_STRING_ROUTINES_I} for UTF-16 character sequences"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-28 10:55:00 GMT (Tuesday 28th July 2026)"
	revision: "1"

class
	XT_STRING_16_ROUTINES_I

inherit
	XT_STRING_ROUTINES_I
		redefine
			advance, area_count, char_width, copy_characters, latin_1_count
		end

feature {NONE} -- Implementation

	advance (index: INTEGER): INTEGER
		do
			Result := index + 2
		end

	area_count (a_latin_1_count: INTEGER): INTEGER
		do
			Result := a_latin_1_count * 2
		end

	copy_characters (dest, source: SPECIAL [CHARACTER]; source_index, destination_index, count: INTEGER)
		local
			i, j, nb: INTEGER
		do
			from
				i := source_index; j := destination_index
				nb := destination_index + count
			until
				j = nb
			loop
				dest [j] := source [i]
				i := i + 2
				j := j + 1
			end
		end

	latin_1_count (a_area_count: INTEGER): INTEGER
		require else
			even_count: a_area_count.integer_remainder (2) = 0
		do
			Result := a_area_count // 2
		end

	Char_width: INTEGER = 2

end
