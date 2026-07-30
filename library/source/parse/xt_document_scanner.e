note
	description: "[
		Abstract base for single-table encodings (UTF-8, Latin-1, ASCII).

		Corresponds to struct normal_encoding and normal_* utility functions
		in xmltok.c.

		All scanner dispatch features delegate to the mixin scanner classes
		(XT_CONTENT_SCANNER, XT_PROLOG_SCANNER, XT_LITERAL_SCANNER).
		The key bridge between the scanner mixins and this class is:
		  byte_type (buf, index) -- reads from byte_type_table
		  char_at   (buf, index) -- reads single byte

		Diamond note: XT_SCANNER_HELPERS and XT_ENCODING both declare
		next_token_ptr as a stored attribute.  The scanner-mixin parents are
		given `undefine next_token_ptr` so that XT_ENCODING's single copy
		is used throughout.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 20:42:32 GMT (Saturday 20th June 2026)"
	revision: "1"

class XT_DOCUMENT_SCANNER

inherit
	XT_ENCODING
		rename
			predefined_entity_name as predefined_entity_code
		redefine
			make
		end

	XT_CONTENT_SCANNER
		export
			{XT_PARSING_BUFFERS} same_characters, attribute_intervals
		end

	XT_PROLOG_SCANNER

	XT_LITERAL_SCANNER

	XT_STRING_CONSTANTS

	XT_UTF_8_NAME_CHECKER

create
	make

feature {NONE} -- Initialisation

	make
		do
			Precursor
			entity_cache := attribute_intervals.entity_cache
			create scanned_entity_buffer.make (5)
			create index_x4_buffer.make_empty (4)
		end

feature -- Scanner dispatch (implements XT_ENCODING deferred features)

	scan_content (buf: SPECIAL [CHARACTER]; bt_table: SPECIAL [INTEGER]; start_index, end_index: INTEGER): INTEGER
		do
			Result := content_tok (buf, bt_table, scanned_entity_buffer, start_index, end_index)
		end

	scan_prolog (buf: SPECIAL [CHARACTER]; bt_table: SPECIAL [INTEGER]; start_index, end_index: INTEGER): INTEGER
		do
			Result := prolog_tok (buf, bt_table, start_index, end_index)
		end

	scan_cdata_section (buf: SPECIAL [CHARACTER]; bt_table: SPECIAL [INTEGER]; start_index, end_index: INTEGER): INTEGER
		do
			Result := cdata_section_tok (buf, bt_table, start_index, end_index)
		end

	scan_entity_value (buf: SPECIAL [CHARACTER]; bt_table: SPECIAL [INTEGER]; start_index, end_index: INTEGER): INTEGER
		do
			Result := entity_value_tok (buf, bt_table, scanned_entity_buffer, start_index, end_index)
		end

feature -- Name utilities (implements XT_ENCODING deferred features)

	skip_s (buf: SPECIAL [CHARACTER]; start_index: INTEGER): INTEGER
			-- Index of first non-whitespace byte at or after start_index.
		local
			done: BOOLEAN
		do
			if attached byte_type_table as bt_table then
				from Result := start_index until Result >= buf.count or done loop
					inspect bt_table [buf [Result].code]
						when BT_whitespace, BT_CR, BT_LF then
							Result := Result + 1
					else
						done := True
					end
				end
			end
		end

	name_matches_ascii (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER;
	                    match: STRING_8): BOOLEAN
			-- True if the name at start_index..end_index equals the ASCII string match.
		local
			index, i: INTEGER; ok: BOOLEAN
		do
			index := start_index; i := 1; ok := True
			from until i > match.count or not ok loop
				if index >= end_index or buf [index] /= match [i] then
					ok := False
				else
					index := index + 1; i := i + 1
				end
			end
			Result := ok and index = end_index
		end

	predefined_entity_code (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
		-- Code point for predefined entity
		-- (lt=0x3C, gt=0x3E, amp=0x26, quot=0x22, apos=0x27), or -1 if not a predefined entity.
		do
			Result := -1
			inspect end_index - start_index + 1
				when 2 then
					inspect buf [start_index]
						when 'g' then
							if same_characters (buf, start_index, end_index, Predefined_gt) then
								Result := {ASCII}.Greaterthan -- 0x3E
							end
						when 'l' then
							if same_characters (buf, start_index, end_index, Predefined_lt) then
								Result := {ASCII}.Lessthan -- 0x3C
							end
					else end
				when 3 then
					if same_characters (buf, start_index, end_index, Predefined_amp) then
						Result := {ASCII}.Ampersand -- 0x26
					end
				when 4 then
					inspect buf [start_index]
						when 'q' then
							if same_characters (buf, start_index, end_index, Predefined_quot) then
								Result := {ASCII}.Doublequote -- 0x22
							end
						when 'a' then
							if same_characters (buf, start_index, end_index, Predefined_apos) then
								Result := {ASCII}.Singlequote -- 0x27
							end
					else end
			else end
		end

feature -- Public ID validation

	is_public_id (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): BOOLEAN
		-- True if every byte in start_index..end_index-1 is a valid PubidChar.
		-- Sets bad_char_ptr on failure.
		local
			index: INTEGER; ok: BOOLEAN
		do
			ok := True
			if attached byte_type_table as bt_table then
				from index := start_index until index >= end_index or not ok loop
					inspect bt_table [buf [index].code]
						when	BT_digit, BT_hex_digit, BT_minus, BT_apostrophe, BT_left_parenthesis, BT_right_parenthesis,
								BT_plus, BT_comma, BT_forward_slash, BT_equals, BT_question, BT_CR, BT_LF, BT_semicolon,
								BT_exclamation, BT_asterisk, BT_percent, BT_hash, BT_colon, BT_whitespace,
								BT_name_start, BT_name_only
						then
							index := index + 1
					else
						bad_char_index := index; ok := False
					end
				end
			end
			Result := ok
		end

feature -- Position tracking

	update_position (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; pos: XT_POSITION)
			-- Update line and column numbers by scanning buf[start_index..end_index-1].
		local
			index: INTEGER
		do
			if attached byte_type_table as bt_table then
				from index := start_index until index >= end_index loop
					inspect bt_table [buf [index].code]
						when BT_CR then
							pos.advance_line
							if index + 1 < end_index
								and bt_table [buf [index + 1].code] = BT_LF
							then
								index := index + 1
							end
						when BT_LF then
							pos.advance_line
					else
						pos.advance_column
					end
					index := index + 1
				end
			end
		end

feature {NONE} -- ASCII half table builder (shared by all single-byte encodings)

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
