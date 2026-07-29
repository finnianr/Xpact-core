note
	description: "${XT_NAME_CACHE} with hash value suitable for UTF-16 character sequence"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-28 13:04:00 GMT (Tuesday 28th July 2026)"
	revision: "1"

class
	XT_UTF_16_NAME_CACHE

inherit
	XT_NAME_CACHE
		undefine
			advance, area_count, char_width, copy_characters, latin_1_count, offset_by
		redefine
			hash_index, new_utf_8
		end

	XT_STRING_16_ROUTINES_I

create
	make

feature {NONE} -- Implementation

	hash_index (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
		-- very fast well distributed hash with only 3 components
		local
			first, last, count: NATURAL_32
		do
			count := (end_index - start_index + 1).to_natural_32
			first := buffer [start_index].natural_32_code.bit_or (buffer [start_index + 1].natural_32_code |<< 8)
			inspect count
				when 2 then
					Result := size_remainder (first * Golden_ratio, first * Golden_ratio |>> 16)
			else
				last := buffer [end_index - 1].natural_32_code.bit_or (buffer [end_index].natural_32_code |<< 8)
				Result := size_remainder (first |<< 8, (last |<< 2).bit_xor (count))
			end
		end

	new_utf_8 (name: STRING): STRING
		do
			Result := utf_8_converter.as_utf_8 (name, True)
		end

end
