note
	description: "[
		Concrete UTF-8 encoding.

		The byte-type table is the union of asciitab.h (0x00..0x7F) and
		utf8tab.h (0x80..0xFF), with numeric BT_* constants from
		XT_BYTE_TYPE_CONSTANTS.

		Multi-byte name/validity checks are provided by XT_UTF8_NAME_CHECKER.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-18 19:48:47 GMT (Thursday 18th June 2026)"
	revision: "1"

class XT_UTF_8_SCANNER

inherit
	XT_DOCUMENT_SCANNER
		undefine
			is_name_char_2, is_name_char_3, is_name_char_4,
			is_name_start_char_2, is_name_start_char_3, is_name_start_char_4,
			is_invalid_char_2, is_invalid_char_3, is_invalid_char_4
		end

	XT_UTF_8_NAME_CHECKER

create
	make

feature -- Encoding identity

	min_bytes_per_char: INTEGER = 1
	is_utf_8: BOOLEAN = True
	is_utf_16: BOOLEAN = False

feature -- Byte-type table

	byte_type_table: SPECIAL [INTEGER]
			-- Combined ASCII + UTF-8 upper byte classification table.
		once
			create Result.make_filled (0, 256)
			fill_ascii_half (Result)
			-- 0x80-0xBF: continuation bytes
			Result.fill_with (8, 128, 191)   -- BT_continuation_byte = 8
			-- 0xC0-0xDF: 2-byte lead bytes (is_invalid_char_2 catches 0xC0, 0xC1)
			Result.fill_with (5, 192, 223)   -- BT_lead_2_byte = 5
			-- 0xE0-0xEF: 3-byte lead bytes
			Result.fill_with (6, 224, 239)   -- BT_lead_3_byte = 6
			-- 0xF0-0xF4: 4-byte lead bytes
			Result.fill_with (7, 240, 244)   -- BT_lead_4_byte = 7
			-- 0xF5-0xFD: not valid UTF-8 lead bytes
			Result.fill_with (0, 245, 253)   -- BT_non_xml = 0
			-- 0xFE-0xFF: malformed
			Result [254] := 1; Result [255] := 1   -- BT_malform = 1
		end

feature {NONE} -- Factory

	new_attribute_intervals: XT_UTF_8_ATTRIBUTE_INTERVALS
		-- collected attribute name-value pair indices into `buffer'
		do
			create Result.make (11)
		end
end
