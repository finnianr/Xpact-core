note
	description: "[
		Copies managed pointer of UTF-8 encoded text into UTF-8 character array skipping CR characters
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-30 11:43:00 GMT (Thursday 30th July 2026)"
	revision: "1"

class
	XT_UTF_8_CODEC

inherit
	XT_LATIN_1_CODEC
		redefine
			copy_as_utf_8, is_utf_8
		end

create
	make_shared, make_empty, make_from_string

feature -- Status query

	is_utf_8: BOOLEAN = True

feature -- Basic operations

	copy_as_utf_8 (dest: SPECIAL [CHARACTER]; dest_index, n: INTEGER)
		local
			ptr: POINTER; i, j, i_final: INTEGER; c: CHARACTER
		do
			ptr := area; i_final := count.min (n) - 1
			from i := 0; j := dest_index until i > i_final loop
				c := read_character_8 (ptr, i)
				inspect c when '%R' then
				-- skip '%R'
					do_nothing
				else
					dest [j] := c
					j := j + 1
				end
				i := i + 1
			end
			last_index := i
			utf_8_copied_count := j - dest_index
		end

end
