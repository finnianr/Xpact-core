note
	description: "[
		Concrete Latin-1 (ISO 8859-1) encoding.

		The byte-type table is the union of asciitab.h (0x00..0x7F) and
		latin1tab.h (0x80..0xFF).  There are no multi-byte sequences so
		all is_name_char_2/3/4 predicates return False.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-18 19:02:11 GMT (Thursday 18th June 2026)"
	revision: "1"

class XT_LATIN_1_SCANNER

inherit
	XT_DOCUMENT_SCANNER

create
	make

feature -- Encoding identity

	char_width: INTEGER = 1

	is_utf_8: BOOLEAN = False

	is_utf_16: BOOLEAN = False

feature -- Byte-type table

	byte_type_table: SPECIAL [INTEGER]
			-- Combined ASCII + Latin-1 byte classification table.
		once
			create Result.make_filled (0, 256)
			fill_ascii_half (Result)
			-- 0x80-0xA9: BT_other = 28
			Result.fill_with (28, 128, 169)
			Result [170] := 22   -- BT_name_start ª
			Result.fill_with (28, 171, 180)
			Result [181] := 22   -- BT_name_start µ
			Result [182] := 28   -- BT_other ¶
			Result [183] := 26   -- BT_name_only · (middle dot, name-only char)
			Result [184] := 28   -- BT_other ¸
			Result [185] := 28   -- BT_other ¹
			Result [186] := 22   -- BT_name_start º
			Result.fill_with (28, 187, 191)
			-- 0xC0-0xD6: BT_name_start
			Result.fill_with (22, 192, 214)
			Result [215] := 28   -- BT_other × (multiplication sign)
			-- 0xD8-0xF6: BT_name_start
			Result.fill_with (22, 216, 246)
			Result [247] := 28   -- BT_other ÷ (division sign)
			-- 0xF8-0xFF: BT_name_start
			Result.fill_with (22, 248, 255)
		end

feature {NONE} -- Factory

	new_attribute_intervals: XT_LATIN_1_ATTRIBUTE_INTERVALS
		-- collected attribute name-value pair indices into `buffer'
		do
			create Result.make (11)
		end
end
