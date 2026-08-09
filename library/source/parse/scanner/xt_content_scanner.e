note
	description: "[
		Top-level tokenizers for element content and CDATA section content.

		Corresponds to contentTok and cdataSectionTok in xmltok_impl.c.
		These are the entry points called by the content processor.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 20:34:05 GMT (Saturday 20th June 2026)"
	revision: "1"

deferred class XT_CONTENT_SCANNER

inherit
	XT_TAG_SCANNER
	XT_PI_COMMENT_SCANNER

feature -- Content tokenization

	content_tok (
		buf: SPECIAL [CHARACTER]; bt_table: SPECIAL [INTEGER]; entity_buffer: LIST [STRING]; start_index, end_index: INTEGER
	): INTEGER
			-- Return the token type for the next token in element content.
			-- Sets next_token_index.  Corresponds to contentTok() in xmltok_impl.c.
		require
			valid_start_index: start_index <= end_index and end_index <= buf.count
		local
			index, bt_code, byte_count: INTEGER
		do
			index := start_index
			if index >= end_index then
				Result := Tok_none
			else
				bt_code := bt_table [buf [index].code]
				inspect bt_code
					when BT_lt then
						Result := scan_lt (buf, index + 1, end_index, bt_table)
					when BT_ampersand then
						Result := scan_ref (buf, Tok_data_chars, index + 1, end_index, bt_table, entity_buffer)
					when BT_CR then
						index := index + 1
						if index >= end_index then
							Result := Tok_trailing_cr
						else
							inspect buf [index] when '%N' then
								index := index + 1
							else end
							next_token_index := index
							Result := Tok_data_newline
						end
					when BT_LF then
						next_token_index := index + 1
						Result := Tok_data_newline

					when BT_right_square_bracket then
						index := index + 1
						if index >= end_index then
							Result := Tok_trailing_rsqb
						elseif buf [index] /= ']' then
							-- lone ']', fall through to data chars
							Result := scan_data_chars (buf, bt_table, index, end_index)
						else
							index := index + 1
							if index >= end_index then
								Result := Tok_trailing_rsqb
							elseif buf [index] = '>' then
								-- illegal ']]>' in content
								next_token_index := index
								Result := Tok_invalid
							else
								Result := scan_data_chars (buf, bt_table, index, end_index)
							end
						end
					when BT_non_xml, BT_malform, BT_continuation_byte then
						next_token_index := index
						Result := Tok_invalid

					when BT_lead_2_byte, BT_lead_3_byte, BT_lead_4_byte then
						byte_count := bt_code - 3
						if end_index - index < byte_count then
							Result := Tok_partial_char

						elseif is_invalid_character (buf, index, byte_count) then
							next_token_index := index
							Result := Tok_invalid
						else
							index := index + byte_count
							Result := scan_data_chars (buf, bt_table, index, end_index)
						end
				else
					index := index + 1
					Result := scan_data_chars (buf, bt_table, index, end_index)
				end
			end
		end

	cdata_section_tok (buf: SPECIAL [CHARACTER]; bt_table: SPECIAL [INTEGER]; start_index, end_index: INTEGER): INTEGER
		-- Return the next token inside a CDATA section.
		-- Sets next_token_index.  Corresponds to cdataSectionTok() in xmltok_impl.c.
		require
			valid_range: start_index <= end_index and end_index <= buf.count
		local
			index, bt_code, byte_count: INTEGER
		do
			index := start_index
			if index >= end_index then
				Result := Tok_none
			else
				bt_code := bt_table [buf [index].code]
				inspect bt_code
					when BT_right_square_bracket then
						index := index + 1
						if index >= end_index then
							Result := Tok_partial
						elseif buf [index] /= ']' then
							-- lone ']'
							Result := scan_cdata_data_chars (buf, bt_table, index, end_index)
						else
							index := index + 1
							if index >= end_index then
								Result := Tok_partial
							elseif buf [index] = '>' then
								next_token_index := index + 1
								Result := Tok_cdata_sect_close
							else
								-- ']]' not followed by '>': back up to the second ']' (mirrors C eXpat's ptr -= MINBPC).
								-- scan_cdata_data_chars stops immediately on BT_right_square_bracket,
								-- so next_token_index lands on the second ']' and the next call
								-- will correctly see ']]>' and return Tok_cdata_sect_close.
								Result := scan_cdata_data_chars (buf, bt_table, index - 1, end_index)
							end
						end
					when BT_CR then
						index := index + 1
						if index >= end_index then
							Result := Tok_partial
						else
							inspect buf [index] when '%N' then
								index := index + 1
							else end
							next_token_index := index
							Result := Tok_data_newline
						end
					when BT_LF then
						next_token_index := index + 1
						Result := Tok_data_newline

					when BT_non_xml, BT_malform, BT_continuation_byte then
						next_token_index := index; Result := Tok_invalid

					when BT_lead_2_byte, BT_lead_3_byte, BT_lead_4_byte then
						byte_count := bt_code - 3
						if end_index - index < byte_count then
							Result := Tok_partial_char
						elseif is_invalid_character (buf, index, byte_count) then
							next_token_index := index; Result := Tok_invalid
						else
							index := index + byte_count
							Result := scan_cdata_data_chars (buf, bt_table, index, end_index)
						end
				else
					index := index + 1
					Result := scan_cdata_data_chars (buf, bt_table, index, end_index)
				end
			end
		end

feature {NONE} -- Data character accumulation

	scan_data_chars (buf: SPECIAL [CHARACTER]; bt_table: SPECIAL [INTEGER]; start_index, end_index: INTEGER): INTEGER
		-- Accumulate data characters in content context until a delimiter.
		-- Returns Tok_data_chars.
		local
			index, bt_code, byte_count: INTEGER; done: BOOLEAN
		do
			index := start_index
			from until index >= end_index or done loop
				bt_code := BT_table [buf [index].code]
				inspect bt_code
					when BT_lead_2_byte, BT_lead_3_byte, BT_lead_4_byte then
						byte_count := bt_code - 3
						if end_index - index < byte_count or else is_invalid_character (buf, index, byte_count) then
							next_token_index := index; Result := Tok_data_chars; done := True
						else
							index := index + byte_count
						end

					when BT_right_square_bracket, BT_ampersand, BT_lt, BT_non_xml,
						BT_malform, BT_continuation_byte, BT_CR, BT_LF then
						next_token_index := index; Result := Tok_data_chars; done := True
				else
					index := index + 1
				end
			end
			if not done then
				next_token_index := index; Result := Tok_data_chars
			end
		end

	scan_cdata_data_chars (buf: SPECIAL [CHARACTER]; bt_table: SPECIAL [INTEGER]; start_index, end_index: INTEGER): INTEGER
			-- Accumulate data characters inside a CDATA section.
		local
			index, bt_code, byte_count: INTEGER; done: BOOLEAN
		do
			index := start_index
			from until index >= end_index or done loop
				bt_code := bt_table [buf [index].code]
				inspect bt_code
					when BT_lead_2_byte, BT_lead_3_byte, BT_lead_4_byte then
						byte_count := bt_code - 3
						if end_index - index < byte_count or else is_invalid_character (buf, index, byte_count) then
							next_token_index := index; Result := Tok_data_chars; done := True
						else
							index := index + byte_count
						end

					when BT_non_xml, BT_malform, BT_continuation_byte, BT_CR, BT_LF, BT_right_square_bracket then
						next_token_index := index; Result := Tok_data_chars; done := True
				else
					index := index + 1
				end
			end
			if not done then
				next_token_index := index; Result := Tok_data_chars
			end
		end

end
