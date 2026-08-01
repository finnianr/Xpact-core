note
	description: "[
		Scanners for processing instructions, comments, CDATA section openers,
		and declaration keywords (<!foo).

		Corresponds to scanComment, scanDecl, scanPi, checkPiTarget, scanCdataSection in xmltok_impl.c.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 20:45:44 GMT (Saturday 20th June 2026)"
	revision: "1"

deferred class XT_PI_COMMENT_SCANNER

inherit
	XT_SCANNER_BASE

	XT_STRING_CONSTANTS

feature {NONE} -- PI and comment scanning

	scan_comment (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
			-- Scan comment after '<!-'.  Returns Tok_comment or error.
		require
			valid_range: start_index <= end_index
		local
			index, CR_count: INTEGER; done, has_CR: BOOLEAN
		do
			index := start_index
			if index >= end_index then
				Result := Tok_partial
			elseif buf [index] /= '-' then
				next_token_index := index
				Result := Tok_invalid

			else
				index := index + 1
				from until index >= end_index or done loop
					inspect bt_table [buf [index].code]
						when BT_minus then
							index := index + 1
							if index >= end_index then
								Result := Tok_partial; done := True
							elseif buf [index] = '-' then
								index := index + 1
								if index >= end_index then
									Result := Tok_partial; done := True

								else
									inspect buf [index] when '>' then
										if has_CR then
											CR_count := left_shift_normalization (buf, start_index + 1, index, '>', False)
											next_token_index := index + 1 - CR_count
										else
											next_token_index := index + 1
										end
										Result := Tok_comment; done := True
									else
										next_token_index := index; Result := Tok_invalid; done := True
									end
								end
							end
						when BT_non_xml, BT_malform, BT_continuation_byte then
							next_token_index := index; Result := Tok_invalid; done := True

						when BT_lead_2_byte then
							if end_index - index < 2 then
								Result := Tok_partial_char; done := True
							elseif is_invalid_char_2 (buf, index) then
								next_token_index := index; Result := Tok_invalid; done := True
							else
								index := index + 2
							end
						when BT_lead_3_byte then
							if end_index - index < 3 then
								Result := Tok_partial_char; done := True
							elseif is_invalid_char_3 (buf, index) then
								next_token_index := index; Result := Tok_invalid; done := True
							else
								index := index + 3
							end
						when BT_lead_4_byte then
							if end_index - index < 4 then
								Result := Tok_partial_char; done := True
							elseif is_invalid_char_4 (buf, index) then
								next_token_index := index; Result := Tok_invalid; done := True
							else
								index := index + 4
							end
						when BT_CR then
							has_CR := True
							index := index + 1

					else
						index := index + 1
					end
				end
				if not done then
					Result := Tok_partial
				end
			end
		end

	scan_pi (buf: SPECIAL [CHARACTER]; bt_table: SPECIAL [INTEGER]; start_index, end_index: INTEGER): INTEGER
			-- Scan processing instruction after '<?'.
			-- Returns Tok_pi (or Tok_xml_decl if target is "xml").
		require
			valid_range: start_index <= end_index
		local
			index, token: INTEGER; target_start: INTEGER; done: BOOLEAN
			lower_upper: SPECIAL [INTEGER]
		do
			index := start_index; lower_upper := index_x4_buffer
			target_start := index
			if index >= end_index then
				Result := Tok_partial
			else
				inspect bt_table [buf [index].code]
					when BT_name_start, BT_hex_digit then
						index := index + 1
					when BT_lead_2_byte then
						if end_index - index >= 2 and then not is_invalid_char_2 (buf, index)
							and then is_name_start_char_2 (buf, index)
						then
							index := index + 2
						else
							next_token_index := index; Result := Tok_invalid; done := True
						end
					when BT_lead_3_byte then
						if end_index - index >= 3 and then not is_invalid_char_3 (buf, index)
							and then is_name_start_char_3 (buf, index)
						then index := index + 3
						else
							next_token_index := index; Result := Tok_invalid; done := True
						end
				else
					next_token_index := index; Result := Tok_invalid; done := True
				end
				if not done then
					from until index >= end_index or done loop
						inspect bt_table [buf [index].code]
							when BT_name_start, BT_hex_digit, BT_digit, BT_name_only, BT_minus then
								index := index + 1
							when BT_whitespace, BT_CR, BT_LF then
								token := check_pi_target (buf, target_start, index)
								if token = 0 then
									next_token_index := index; Result := Tok_invalid; done := True
								else
									inspect token when Tok_pi then
										lower_upper.extend (start_index)
										lower_upper.extend (index - 1)
										Result := scan_pi_content (buf, index + 1, end_index, token, bt_table, lower_upper); done := True
										inspect lower_upper.count when 4 then
											attribute_intervals.transfer (buf, lower_upper, scanned_entity_buffer)
										else end
									else
										Result := scan_pi_content (buf, index + 1, end_index, token, bt_table, lower_upper); done := True
									end
								end
							when BT_question then
								token := check_pi_target (buf, target_start, index)
								if token = 0 then
									next_token_index := index; Result := Tok_invalid; done := True
								else
									index := index + 1
									if index >= end_index then
										Result := Tok_partial; done := True
									elseif buf [index] = '>' then
										next_token_index := index + 1
										Result := token; done := True
									else
										next_token_index := index; Result := Tok_invalid; done := True
									end
								end
						else
							next_token_index := index; Result := Tok_invalid; done := True
						end
					end
					if not done then
						Result := Tok_partial
					end
				end
			end
			inspect Result when Tok_partial then
				attribute_intervals.wipe_out
			else end
		end

	scan_decl (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
			-- Scan declaration keyword after '<!'.  Returns Tok_decl_open or error.
		require start_index <= end_index
		local
			index: INTEGER; done: BOOLEAN
		do
			index := start_index
			if index >= end_index then
				Result := Tok_partial

			else
				inspect bt_table [buf [index].code]
					when BT_minus then
						Result := scan_comment (buf, index + 1, end_index, bt_table)

					when BT_left_square_bracket then
						next_token_index := index + 1
						Result := Tok_cond_sect_open

					when BT_name_start, BT_hex_digit then
						index := index + 1
						from until index >= end_index or done loop
							inspect bt_table [buf [index].code]
								when BT_name_start, BT_hex_digit then
									index := index + 1
								when BT_whitespace, BT_CR, BT_LF, BT_percent then
									next_token_index := index
									Result := Tok_decl_open; done := True
							else
								next_token_index := index
								Result := Tok_invalid; done := True
							end
						end
						if not done then
						Result := Tok_partial
				end
				else
					next_token_index := index; Result := Tok_invalid
				end
			end
		end

	scan_cdata_section_open (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
			-- Verify 'CDATA[' after '<!['.  Returns Tok_cdata_sect_open or error.
		require
			start_index <= end_index
		do
			if end_index - start_index < Cdata_lsqb.count then
				Result := Tok_partial
			else
				if starts_with (buf, start_index, Cdata_lsqb) then
					Result := Tok_cdata_sect_open
					next_token_index := start_index + Cdata_lsqb.count
				else
					Result := Tok_invalid
					next_token_index := start_index + match_count (buf, start_index, Cdata_lsqb) + 1
				end
			end
		end

feature {NONE} -- PI helpers

	check_pi_target (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
			-- Return Tok_xml_decl if target is exactly "xml" (case-sensitive),
			-- Tok_pi otherwise, or 0 if target is a case variation of "xml"
			-- (forbidden by XML spec: "<?XML" etc. are reserved).
		do
			if end_index - start_index = 3 then
				inspect buf [start_index] when 'x' then
					if same_characters (buf, start_index, start_index + 2, Xml_lower) then
						Result := Tok_xml_decl
					elseif same_caseless_characters (buf, start_index, start_index + 2, Xml_lower) then
						Result := 0 -- reserved; caller treats as invalid
					else
						Result := Tok_pi
					end
				else
					Result := Tok_pi
				end
			else
				Result := Tok_pi
			end
		end

	scan_pi_content (
		buf: SPECIAL [CHARACTER]; a_start_index, end_index, token: INTEGER
		bt_table: SPECIAL [INTEGER]; lower_upper: SPECIAL [INTEGER]
	): INTEGER
			-- Scan PI content until '?>'.  Returns token (Tok_pi or Tok_xml_decl).
		local
			index, start_index: INTEGER; done, passed_leading: BOOLEAN
		do
			from index := a_start_index until index > end_index or passed_leading loop
				inspect buf [index]
					when '%T', '%N', '%/32/' then
						index := index + 1
				else
					passed_leading := True
				end
			end
			start_index := index
			from until index >= end_index or done loop
				inspect bt_table [buf [index].code]
					when BT_non_xml, BT_malform, BT_continuation_byte then
						next_token_index := index; Result := Tok_invalid; done := True
					when BT_lead_2_byte then
						if end_index - index < 2 then
							Result := Tok_partial_char; done := True
						elseif is_invalid_char_2 (buf, index) then
							next_token_index := index; Result := Tok_invalid; done := True
						else
							index := index + 2
						end
					when BT_lead_3_byte then
						if end_index - index < 3 then
							Result := Tok_partial_char; done := True
						elseif is_invalid_char_3 (buf, index) then
							next_token_index := index; Result := Tok_invalid; done := True
						else
							index := index + 3
						end
					when BT_lead_4_byte then
						if end_index - index < 4 then
							Result := Tok_partial_char; done := True
						elseif is_invalid_char_4 (buf, index) then
							next_token_index := index; Result := Tok_invalid; done := True
						else
							index := index + 4
						end
					when BT_question then
						index := index + 1
						if index >= end_index then
							Result := Tok_partial; done := True
						elseif buf [index] = '>' then
							inspect token when Tok_pi then
								lower_upper.extend (start_index)
								lower_upper.extend (index - 2)
							else end
							next_token_index := index + 1
							Result := token; done := True
						end
				else
					index := index + 1
				end
			end
			if not done then
				Result := Tok_partial
			end
			inspect Result when Tok_partial then
				lower_upper.wipe_out
			else end
		end

end
