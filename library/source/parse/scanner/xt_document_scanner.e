note
	description: "Corresponds to struct normal_encoding and normal_* utility functions in eXpath xmltok.c"
	notes: "[
		**From Claude AI**

		All scanner dispatch features delegate to the mixin scanner classes ${XT_CONTENT_SCANNER},
		${XT_PROLOG_SCANNER} and ${XT_LITERAL_SCANNER}.

		The key bridge between the scanner mixins and this class is:

			byte_type (buf, index) -- reads from byte_type_table
			char_at   (buf, index) -- reads single byte
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 20:42:32 GMT (Saturday 20th June 2026)"
	revision: "1"

class XT_DOCUMENT_SCANNER

inherit
	XT_CONTENT_SCANNER
		export
			{XT_PARSING_BUFFERS} same_characters, attribute_intervals
		end

	XT_PROLOG_SCANNER
		export
			{XT_PARSING_BUFFERS} scan_name
		end

create
	make

feature {NONE} -- Initialisation

	make
		do
			create attribute_intervals.make (11)
			entity_cache := attribute_intervals.entity_cache
			create scanned_entity_buffer.make (5)
			create index_x4_buffer.make_empty (4)
		end

feature -- Scanner dispatch (implements XT_ENCODING deferred features)

	scan_content (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
			-- Scan the next token in element content.
			-- Sets `next_token_index'.  Corresponds to scanners[XML_CONTENT_STATE].
		require
			valid_range: start_index >= 0 and start_index <= end_index and end_index <= buf.count
		do
			Result := content_tok (buf, start_index, end_index, bt_table, scanned_entity_buffer)
		ensure
			result_in_range: Result >= Tok_trailing_rsqb and Result <= Tok_ignore_sect
		end

	scan_prolog (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
			-- Scan the next token in the document prolog or DTD.
			-- Corresponds to scanners[XML_PROLOG_STATE].
		require
			valid_range: start_index >= 0 and start_index <= end_index and end_index <= buf.count
		do
			Result := prolog_tok (buf, start_index, end_index, bt_table)
		end

	scan_cdata_section (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
			-- Scan the next token inside a CDATA section.
			-- Corresponds to scanners[XML_CDATA_SECTION_STATE].
		require
			valid_range: start_index >= 0 and start_index <= end_index and end_index <= buf.count
		do
			Result := cdata_section_tok (buf, start_index, end_index, bt_table)
		end

	scan_entity_value (
		buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]
		entity_buffer: LIST [STRING]
	): INTEGER
			-- Scan the next token inside an entity value literal.
			-- Corresponds to literalScanners[XML_ENTITY_VALUE_LITERAL].
		require
			valid_range: start_index >= 0 and start_index <= end_index and end_index <= buf.count
		do
			Result := entity_value_tok (buf, start_index, end_index, bt_table, entity_buffer)
		end

feature -- Name utilities (implements XT_ENCODING deferred features)

	entity_value_tok (
		buf: SPECIAL [CHARACTER] start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]; entity_buffer: LIST [STRING]
	): INTEGER
			-- Tokenize inside an entity value literal.
			-- Corresponds to entityValueTok() in xmltok_impl.c.
		require
			valid_range: start_index <= end_index and end_index <= buf.count
		local
			index, start, byte_count, bt_code: INTEGER; done: BOOLEAN
		do
			index := start_index; start := index
			if index >= end_index then
				Result := Tok_none

			else
				from until index >= end_index or done loop
					bt_code := bt_table [buf [index].code]
					inspect bt_code
						when BT_non_xml, BT_malform, BT_continuation_byte then
							next_token_index := index; Result := Tok_invalid; done := True

						when BT_lead_2_byte, BT_lead_3_byte, BT_lead_4_byte then
							byte_count := bt_code - 3
							if end_index - index < byte_count then
								Result := Tok_partial_char; done := True

							elseif is_invalid_character (buf, index, byte_count) then
								next_token_index := index
								Result := Tok_invalid; done := True
							else
								index := index + byte_count
							end
						when BT_ampersand then
							if index = start then
								Result := scan_ref (buf, Tok_literal, index + 1, end_index, bt_table, entity_buffer)
							else
								next_token_index := index; Result := Tok_data_chars
							end
							done := True
						when BT_percent then
							if index = start then
								-- % starts a parameter entity reference inside entity values
								-- treat as invalid here (caller
								-- (should use prolog scanner)
								next_token_index := index; Result := Tok_invalid
							else
								next_token_index := index; Result := Tok_data_chars
							end
							done := True
						when BT_LF then
							if index = start then
								next_token_index := index + 1; Result := Tok_data_newline
							else
								next_token_index := index; Result := Tok_data_chars
							end
							done := True
						when BT_CR then
							if index = start then
								index := index + 1
								if index >= end_index then
									Result := Tok_trailing_CR
								else
									inspect bt_table [buf [index].code] when BT_LF then
										index := index + 1
									end
									next_token_index := index; Result := Tok_data_newline
								end
							else
								next_token_index := index; Result := Tok_data_chars
							end
							done := True
					else
						index := index + 1
					end
				end
				if not done then
					next_token_index := index; Result := Tok_data_chars
				end
			end
		end

	skip_whitespace (buf: SPECIAL [CHARACTER]; start_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
			-- Index of first non-whitespace byte at or after start_index.
		require
			valid_start_index: start_index >= 0
		local
			done: BOOLEAN
		do
			from Result := start_index until Result >= buf.count or done loop
				inspect bt_table [buf [Result].code]
					when BT_whitespace, BT_CR, BT_LF then
						Result := Result + 1
				else
					done := True
				end
			end
		ensure
			result_gte_index: Result >= start_index
		end

	name_matches_ascii (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; match: STRING_8): BOOLEAN
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

feature -- Status query

	is_public_id (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): BOOLEAN
			-- True when `buf [start_index] .. buf [end_index]' is a valid PUBLIC identifier literal.
			-- On False, `bad_char_index' is set to the invalid character's index.
		local
			index: INTEGER; ok: BOOLEAN
		do
			ok := True
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
			Result := ok
		end

feature -- Position tracking

	update_position (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; pos: XT_POSITION; bt_table: SPECIAL [INTEGER])
			-- Update line and column numbers by scanning `buf [start_index] .. buf [end_index - 1]'
		require
			valid_range: start_index >= 0 and start_index <= end_index and end_index <= buf.count
		local
			index: INTEGER
		do
			from index := start_index until index >= end_index loop
				inspect bt_table [buf [index].code]
					when BT_CR then
						pos.advance_line
						if index + 1 < end_index and buf [index + 1] = '%N' then
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
