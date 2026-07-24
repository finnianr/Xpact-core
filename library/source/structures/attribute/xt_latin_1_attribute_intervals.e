note
	description: "[
		List of indices demarking name-value attribute pair substrings in ${XT_XML_PARSER}.buffer
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-24 17:58:41 GMT (Friday 24th July 2026)"
	revision: "1"

class
	XT_LATIN_1_ATTRIBUTE_INTERVALS

inherit
	XT_ATTRIBUTE_BUFFER_INTERVALS

create
	make

feature -- Status report

	valid_utf_8 (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): BOOLEAN
		-- True if character in `buf' from `start_index .. end_index' are already
		-- valid as UTF-8
		local
			i: INTEGER
		do
			Result := True
			from i := start_index until i > end_index or not Result loop
				Result := buf [i].code < 128
				i := i + 1
			end
		end

feature {NONE} -- Factory

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (n)
		end

feature {NONE} -- Implementation

	to_utf_8 (src, dst: SPECIAL [CHARACTER]; start_index, end_index: INTEGER)
			-- Latin-1 to UTF-8 transcoding.  Sets consumed_from and written_to.
		local
			i: INTEGER; c_i: CHARACTER
		do
			from i := start_index until i > end_index or dst.count = dst.capacity loop
				c_i := src [i]
				if c_i.code < 0x80 then
					dst.extend (c_i)

				elseif dst.count + 2 <= dst.capacity then
					dst.extend ((0xC0 | (c_i.code |>> 6)).to_character_8)
					dst.extend ((0x80 | (c_i.code & 0x3F)).to_character_8)
				else
					i := end_index + 1 -- no room; stop
				end
				i := i + 1
			end
			written_to := dst.count
		end

	to_utf_16 (src: SPECIAL [CHARACTER]; dst: SPECIAL [NATURAL_16]; start_index, end_index: INTEGER)
			-- Latin-1 to UTF-16: each byte is its code point (U+0000..U+00FF).
		local
			i: INTEGER
		do
			from i := start_index until i > end_index or dst.count = dst.capacity loop
				dst.extend (src [i].code.to_natural_16)
				i := i + 1
			end
			written_to := dst.count
		end

end
