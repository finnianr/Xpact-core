note
	description: "[
		Concrete ASCII encoding.

		Identical to XT_LATIN1_ENCODING for the lower 128 bytes;
		all upper bytes (0x80..0xFF) are BT_non_xml (not valid in ASCII XML).
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-18 19:02:35 GMT (Thursday 18th June 2026)"
	revision: "1"

class XT_ASCII_SCANNER

inherit
	XT_DOCUMENT_SCANNER

create
	make

feature -- Encoding identity

	min_bytes_per_char: INTEGER = 1

	is_utf_8: BOOLEAN = False
	is_utf_16: BOOLEAN = False

feature -- Byte-type table

	byte_type_table: SPECIAL [INTEGER]
			-- ASCII table: lower half from asciitab.h, upper half all BT_non_xml.
		once
			create Result.make_filled (0, 256)  -- 0 = BT_non_xml covers 0x80-0xFF
			fill_ascii_half (Result)
		end

feature {NONE} -- Factory

	new_attribute_intervals: XT_ASCII_ATTRIBUTE_INTERVALS
		-- collected attribute name-value pair indices into `buffer'
		do
			create Result.make (11)
		end
end
