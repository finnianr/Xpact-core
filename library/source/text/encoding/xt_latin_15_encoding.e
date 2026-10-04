note
	description: "Implementation of ${XT_CUSTOM_ENCODING_I} for ISO-8859-15 character set"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-10-02 10:42:00 GMT (Saturday 2nd October 2026)"
	revision: "1"

class
	XT_LATIN_15_ENCODING

inherit
	XT_CUSTOM_ENCODING_I

create
	make

feature {NONE} -- Implementation

	fill_not_identity
		local
			ptr: POINTER
		do
			ptr := self_ptr
			c_set_map_code (ptr, 0xA4, 0x20AC) -- '€' (Latin-1: '¤')
			c_set_map_code (ptr, 0xA6, 0x0160) -- 'Š' (Latin-1: '¦')
			c_set_map_code (ptr, 0xA8, 0x0161) -- 'š' (Latin-1: '¨')
			c_set_map_code (ptr, 0xB4, 0x017D) -- 'Ž' (Latin-1: '´')
			c_set_map_code (ptr, 0xB8, 0x017E) -- 'ž' (Latin-1: '¸')
			c_set_map_code (ptr, 0xBC, 0x0152) -- 'Œ' (Latin-1: '¼')
			c_set_map_code (ptr, 0xBD, 0x0153) -- 'œ' (Latin-1: '½')
			c_set_map_code (ptr, 0xBE, 0x0178) -- 'Ÿ' (Latin-1: '¾')
		end

end
