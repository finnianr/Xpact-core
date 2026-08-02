note
	description: "[
		Primitive byte-level operations shared by all scanner mixin classes.

		Scanner mixins inherit this class to obtain `byte_type', `char_at',
		`next_token_index', and the multi-byte name-character checks.  The
		concrete encoding provides effective implementations.

		The C macros this replaces:
		  BYTE_TYPE(enc, p)         -> byte_type (buf, index)
		  BYTE_TO_ASCII(enc, p)     -> char_at (buf, index)
		  CHAR_MATCHES(enc, p, c)   -> char_at (buf, index) = c
		  MINBPC(enc)               -> char_width
		  HAS_CHAR(enc, p, end)     -> index < end_index   (written inline)
		  HAS_CHARS(enc, p, end, n) -> end_index - index >= n * char_width
		  IS_NAME_CHAR(enc, p, n)   -> is_name_char_n (buf, index)
		  IS_NMSTRT_CHAR(enc, p, n) -> is_name_start_char_n (buf, index)
		  IS_INVALID_CHAR(enc, p, n)-> is_invalid_char_n (buf, index)
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 20:20:51 GMT (Saturday 20th June 2026)"
	revision: "1"

deferred class XT_SCANNER_BASE

inherit
	XT_BYTE_TYPE_CONSTANTS; XT_TOKEN_CONSTANTS; XT_STRING_CONSTANTS

	XT_STRING_ROUTINES_I
		export
			{XT_XML_PARSER_BASE} all
		end

feature -- Status report

	newline_or_tab_found: BOOLEAN

feature -- Multi-byte name-character checks

-- UTF-8; deferred for UTF-16/etc.
-- never called for single-byte encoding

	is_name_char_2 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
			-- True when the 2-byte UTF-8 sequence at index is an XML name character.
		require
			valid_index: index + 1 < buf.count
		deferred
		end

	is_name_char_3 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
			-- True when the 3-byte UTF-8 sequence at index is an XML name character.
		require
			valid_index: index + 2 < buf.count
		deferred
		end

	is_name_char_4 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
			-- True when the 4-byte UTF-8 sequence at index is an XML name character.
		require
			valid_index: index + 3 < buf.count
		deferred
		end

	is_name_start_char_2 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
			-- True when the 2-byte UTF-8 sequence at index can start an XML name.
		require
			valid_index: index + 1 < buf.count
		deferred
		end

	is_name_start_char_3 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
		require
			valid_index: index + 2 < buf.count
		deferred
		end

	is_name_start_char_4 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
		require
			valid_index: index + 3 < buf.count
		deferred
		end

	is_invalid_char_2 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
			-- True when the 2-byte sequence at index is not a valid Unicode scalar.
		require
			valid_index: index + 1 < buf.count
		deferred
		end

	is_invalid_char_3 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
		require
			valid_index: index + 2 < buf.count
		deferred
		end

	is_invalid_char_4 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
		require
			valid_index: index + 3 < buf.count
		deferred
		end

feature {NONE} -- Implementation

	fill_ascii_half (t: SPECIAL [INTEGER])
			-- Fill entries 0..127 with BT_* values from asciitab.h.
		do
			-- 0x00-0x08, 0x0B-0x0C, 0x0E-0x1F: BT_non_xml = 0 (make_filled default)
			t [9]  := 21; t [10] := 10; t [13] := 9   -- tab, LF, CR
			t [32] := 21; t [33] := 16; t [34] := 12; t [35] := 19
			t [36] := 28; t [37] := 30; t [38] := 3;  t [39] := 13
			t [40] := 31; t [41] := 32; t [42] := 33; t [43] := 34
			t [44] := 35; t [45] := 27; t [46] := 26; t [47] := 17
			t.fill_with (25, 48, 57)     -- BT_digit '0'..'9'
			t [58] := 23; t [59] := 18; t [60] := 2;  t [61] := 14
			t [62] := 11; t [63] := 15; t [64] := 28
			t.fill_with (24, 65, 70)     -- BT_hex_digit 'A'..'F'
			t.fill_with (22, 71, 90)     -- BT_name_start 'G'..'Z'
			t [91] := 20; t [92] := 28; t [93] := 4;  t [94] := 28
			t [95] := 22; t [96] := 28  -- '_', '`'
			t.fill_with (24, 97, 102)    -- BT_hex_digit 'a'..'f'
			t.fill_with (22, 103, 122)   -- BT_name_start 'g'..'z'
			t [123] := 28; t [124] := 36; t [125] := 28
			t [126] := 28; t [127] := 28
		end

	leading_10 (buf: SPECIAL [CHARACTER]; index: INTEGER): STRING_8
		-- leading 10 characters in `buf' starting from `index'
		local
			upper: INTEGER
		do
			upper := (buf.count - 1).min (index + 10)
			Result := area_substring (buf, index, upper, True)
		end

	has_chars (end_index, index, count: INTEGER): BOOLEAN
			-- end_index - index >= count * char_width  (HAS_CHARS macro)
		do
			Result := end_index - index >= count
		end

feature {NONE} -- Internal attributes

	next_token_index: INTEGER

	index_x4_buffer: SPECIAL [INTEGER]

	scanned_entity_buffer: ARRAYED_LIST [STRING]

feature {XT_XML_PARSER_BASE} -- Deferred

	attribute_intervals: XT_ATTRIBUTE_BUFFER_INTERVALS
		-- collected attribute name-value pair indices into `buffer'
		deferred
		end

feature -- Constants

	Byte_type_table: SPECIAL [INTEGER]
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

end
