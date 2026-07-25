note
	description: "[
		List of indices demarking name-value attribute pair substrings in ${XT_XML_PARSER}.buffer
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-24 18:00:41 GMT (Friday 24th July 2026)"
	revision: "1"

class
	XT_ASCII_ATTRIBUTE_INTERVALS

inherit
	XT_ATTRIBUTE_BUFFER_INTERVALS

create
	make

feature -- Measurement

	utf_8_bytes_count (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
			-- Number of bytes necessary to encode in UTF-8 `s.substring (start_index, end_index)'.
		do
			Result := end_index - start_index + 1
		end

feature {NONE} -- Factory

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (n)
		end

feature {NONE} -- Implementation

	to_utf_8 (src, dst: SPECIAL [CHARACTER]; start_index, end_index: INTEGER)
			-- ASCII to UTF-8: identical bytes (all code points < 0x80).
		local
			l_count: INTEGER
		do
			l_count := (end_index - start_index + 1).min (dst.capacity)
			dst.copy_data (src, start_index, end_index, l_count)
		end

	to_utf_16 (src: SPECIAL [CHARACTER]; dst: SPECIAL [NATURAL_16]; start_index, end_index: INTEGER)
			-- ASCII to UTF-16.
		local
			i: INTEGER
		do
			from i := start_index until i > end_index or dst.count = dst.capacity loop
				dst.extend (src [i].code.to_natural_16)
				i := i + 1
			end
		end

end
