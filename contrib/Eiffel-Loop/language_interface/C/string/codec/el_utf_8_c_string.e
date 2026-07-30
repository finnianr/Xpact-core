note
	description: "Managed C string that is assumed to be encoded as UTF-8"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-30 11:43:00 GMT (Thursday 30th July 2026)"
	revision: "1"

class
	EL_UTF_8_C_STRING

inherit
	EL_LATIN_1_C_STRING
		redefine
			copy_as_utf_8
		end

create
	make, make_filled, make_from_string, make_shared, make_empty

convert
	make_from_string ({STRING_8})

feature -- Basic operations

	copy_as_utf_8 (dest: SPECIAL [CHARACTER]; dest_index, n: INTEGER)
		local
			ptr: POINTER; i, j, i_final: INTEGER
		do
			utf_8_copied_count := count.min (n)
			ptr := area; i_final := utf_8_copied_count - 1
			from i := 0; j := dest_index until i > i_final loop
				dest [j] := read_character_8 (ptr, i)
				i := i + 1
				j := j + 1
			end
			last_index := i
		end
end
