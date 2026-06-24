note
	description: "[
		Scanner for start tags, empty-element tags, end tags, and attribute lists.

		Corresponds to scanLt, scanEndTag, scanAtts in xmltok_impl.c.
		Entry points are positioned one byte past the sigil already consumed:
		  scan_lt      : past '<'
		  scan_end_tag : past '</'
		  scan_atts    : past first character of the first attribute name
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 20:32:53 GMT (Saturday 20th June 2026)"
	revision: "1"

deferred class XT_TAG_SCANNER

inherit
	XT_SCANNER_HELPERS
	XT_REF_SCANNER

feature -- Element change

	set_attribute_indices (a_attribute_indices: XT_STRING_INTERVALS)
		do
			attribute_intervals_list := a_attribute_indices
		end

feature -- Measurement

	tag_name_count: INTEGER

feature {NONE} -- Tag scanning

	scan_lt (buf: SPECIAL [CHARACTER]; start_index, a_end: INTEGER): INTEGER
			-- Dispatch on the character after '<'.
			-- Returns the appropriate XML_TOK_* code; sets next_token_ptr.
		require
			valid_range: start_index <= a_end
		local
			index: INTEGER
		do
			index := start_index
			if index >= a_end then
				Result := Tok_partial
			else
				inspect byte_type (buf, index)
					when BT_exclamation then
						index := advance (index)
						if index >= a_end then
							Result := Tok_partial
						else
							inspect byte_type (buf, index)
								when BT_minus then
									Result := scan_comment (buf, advance (index), a_end)
								when BT_left_square_bracket then
									Result := scan_cdata_section_open (buf, advance (index), a_end)
							else
								next_token_index := index
								Result := Tok_invalid
							end
						end
					when BT_question then
						Result := scan_pi (buf, advance (index), a_end)
					when BT_forward_slash then
						Result := scan_end_tag (buf, advance (index), a_end)
					when BT_name_start, BT_hex_digit then
						index := advance (index)
						Result := scan_start_tag_name (buf, byte_type_table, index, a_end)
					when BT_lead_2_byte then
						if a_end - index >= 2 and then not is_invalid_char_2 (buf, index)
							and then is_name_start_char_2 (buf, index)
						then
							index := index + 2
							Result := scan_start_tag_name (buf, byte_type_table, index, a_end)
						else
							next_token_index := index
							Result := Tok_invalid
						end
					when BT_lead_3_byte then
						if a_end - index >= 3 and then not is_invalid_char_3 (buf, index)
							and then is_name_start_char_3 (buf, index)
						then
							index := index + 3
							Result := scan_start_tag_name (buf, byte_type_table, index, a_end)
						else
							next_token_index := index
							Result := Tok_invalid
						end
				else
					next_token_index := index
					Result := Tok_invalid
				end
			end
		end

	scan_end_tag (buf: SPECIAL [CHARACTER]; start_index, a_end: INTEGER): INTEGER
			-- Scan end tag after '</'.  Returns Tok_end_tag or error.
		require
			valid_range: start_index <= a_end
		local
			index, name_count: INTEGER; done: BOOLEAN
		do
			index := start_index; name_count := 1
			if index >= a_end then
				Result := Tok_partial
			else
				inspect byte_type (buf, index)
					when BT_name_start, BT_hex_digit then
						index := advance (index)
					when BT_lead_2_byte then
						if a_end - index >= 2 and then not is_invalid_char_2 (buf, index)
							and then is_name_start_char_2 (buf, index)
						then
							index := index + 2
						else
							next_token_index := index; Result := Tok_invalid; done := True
						end
					when BT_lead_3_byte then
						if a_end - index >= 3  and then not is_invalid_char_3 (buf, index)
							and then is_name_start_char_3 (buf, index)
						then
							index := index + 3
						else
							next_token_index := index; Result := Tok_invalid; done := True
						end
				else
					next_token_index := index; Result := Tok_invalid; done := True
				end
				if not done and then attached byte_type_table as bt_table then
					from until index >= a_end or done loop
						inspect bt_table [buf [index].code].to_integer_32
							when BT_name_start, BT_hex_digit, BT_digit, BT_name_only,
								BT_minus, BT_colon then
								name_count := name_count + 1
								index := advance (index)
							when BT_whitespace, BT_CR, BT_LF then
								index := advance (index)
								from until index >= a_end or done loop
									inspect bt_table [buf [index].code].to_integer_32
										when BT_whitespace, BT_CR, BT_LF then
											index := advance (index)
										when BT_gt then
											next_token_index := advance (index)
											Result := Tok_end_tag
											done := True
									else
										next_token_index := index
										Result := Tok_invalid
										done := True
									end
								end
								if not done then
									Result := Tok_partial; done := True
								end
							when BT_gt then
								next_token_index := advance (index)
								Result := Tok_end_tag
								done := True
						else
							next_token_index := index
							Result := Tok_invalid
							done := True
						end
					end
					if not done then
						Result := Tok_partial
					end
				end
			end
			tag_name_count := name_count
		end

	scan_attributes (buf: SPECIAL [CHARACTER]; intervals_list: XT_STRING_INTERVALS; start_index, a_end: INTEGER): INTEGER
		-- Scan attribute list starting at the first attribute name character.
		-- Returns Tok_start_tag_with_atts, Tok_empty_element_with_atts, or error.
		require
			valid_range: start_index <= a_end
		local
			index, open, byte: INTEGER; done: BOOLEAN
		do
			index := start_index
			if attached byte_type_table as bt_table and then attached intervals_list.additions_buffer as index_buffer then
				index_buffer.extend (index) -- name lower
				from until index >= a_end or done loop
					byte := bt_table [buf [index].code].to_integer_32
					inspect byte
						when BT_name_start, BT_hex_digit, BT_digit, BT_name_only, BT_minus, BT_colon, BT_lead_2_byte, BT_lead_3_byte,
							BT_lead_4_byte then
							inspect index_buffer.count when 0 then
								index_buffer.extend (index - 1) -- name lower
							else
							end
							index := advance (index)
						when BT_whitespace, BT_CR, BT_LF then
						-- Skip one whitespace byte; outer loop handles subsequent chars naturally.
						-- Whitespace may separate a name from '=' or one attribute from the next.
							inspect index_buffer.count when 1 then
								index_buffer.extend (index - 1) -- name upper
							else end
							index := advance (index)
						when BT_equals then
							inspect index_buffer.count when 1 then
								index_buffer.extend (index - 1) -- name upper
							else end
							index := advance (index)
							Result := scan_attribute_value (bt_table, buf, index_buffer, index, a_end, open)
							inspect Result
								when Tok_partial, Tok_partial_char then
									intervals_list.wipe_out
							else
								intervals_list.update
							end
							if Result /= 0 then
								done := True
							else
								index := next_token_index
							end
						when BT_gt then
							next_token_index := advance (index)
							Result := Tok_start_tag_with_atts
							done := True
						when BT_forward_slash then
							index := advance (index)
							if index >= a_end then
								Result := Tok_partial; done := True
							elseif buf [index] = '>' then
								next_token_index := advance (index)
								Result := Tok_empty_element_with_atts
								done := True
							else
								next_token_index := index; Result := Tok_invalid; done := True
							end
					else
						next_token_index := index; Result := Tok_invalid; done := True
					end
				end
			end
			if not done then
				Result := Tok_partial
				intervals_list.wipe_out
			end
		ensure
			attribute_indices_divisible_by_4: -- name and value have 2 indices each
				Result /= Tok_partial implies attribute_intervals_list.count \\ 4 = 0
		end

feature {NONE} -- Tag sub-helpers

	scan_start_tag_name (buf: SPECIAL [CHARACTER]; bt_table: SPECIAL [NATURAL_8]; start_index, a_end: INTEGER): INTEGER
			-- After consuming name-start char(s); scan rest of start tag name.
		local
			index, name_count: INTEGER; done: BOOLEAN
		do
			index := start_index; name_count := 1
			from until index >= a_end or done loop
				inspect bt_table [buf [index].code].to_integer_32
					when BT_name_start, BT_hex_digit, BT_digit, BT_name_only, BT_minus, BT_colon, BT_lead_2_byte,
						BT_lead_3_byte, BT_lead_4_byte then
						name_count := name_count + 1
						index := advance (index)
					when BT_whitespace, BT_CR, BT_LF then
						index := advance (index)
						from until index >= a_end or done loop
							inspect bt_table [buf [index].code].to_integer_32
								when BT_name_start, BT_hex_digit then
									Result := scan_attributes (buf, attribute_intervals_list, index, a_end); done := True
								when BT_gt then
									next_token_index := advance (index)
									Result := Tok_start_tag_no_atts; done := True
								when BT_forward_slash then
									index := advance (index)
									if index >= a_end then
										Result := Tok_partial; done := True
									elseif buf [index] = '>' then
										next_token_index := advance (index)
										Result := Tok_empty_element_no_atts; done := True
									else
										next_token_index := index; Result := Tok_invalid; done := True
									end
								when BT_whitespace, BT_CR, BT_LF then
									index := advance (index)
							else
								next_token_index := index; Result := Tok_invalid; done := True
							end
						end
						if not done then
							Result := Tok_partial; done := True
						end
					when BT_gt then
						next_token_index := advance (index)
						Result := Tok_start_tag_no_atts; done := True
					when BT_forward_slash then
						index := advance (index)
						if index >= a_end then
							Result := Tok_partial; done := True
						elseif buf [index] = '>' then
							next_token_index := advance (index)
							Result := Tok_empty_element_no_atts; done := True
						else
							next_token_index := index; Result := Tok_invalid; done := True
						end
				else
					next_token_index := index; Result := Tok_invalid; done := True
				end
			end
			if done then
				tag_name_count := name_count
			else
				Result := Tok_partial
			end
		end

	scan_attribute_value (
		bt_table: SPECIAL [NATURAL_8]; buf: SPECIAL [CHARACTER]; index_buffer: SPECIAL [INTEGER]
		start_index, a_end, open: INTEGER
	): INTEGER
			-- Scan past whitespace to the opening quote, then the value up to matching
			-- close quote.  Sets next_token_ptr past the closing quote.
			-- Returns 0 (caller should continue) or a non-zero error/end token code.
		require
			index_buffer_has_name: index_buffer.count = 2
		local
			index, opening_quote: INTEGER; done, closed: BOOLEAN
		do
			index := start_index
			-- skip to opening quote
			from until index >= a_end or done loop
				inspect bt_table [buf [index].code].to_integer_32
					when BT_quote then
						opening_quote := BT_quote; done := True
					when BT_apostrophe then
						opening_quote := BT_apostrophe; done := True
					when BT_whitespace, BT_LF, BT_CR then
						index := advance (index)
				else
					next_token_index := index; Result := Tok_invalid; done := True
				end
			end
			if done and Result = 0 then
			-- scan value content up to matching closing quote
				index := advance (index)  -- skip opening quote
				index_buffer.extend (index) -- value lower
				from until index >= a_end or closed loop
					inspect bt_table [buf [index].code].to_integer_32
						when BT_quote then
							inspect opening_quote
								when BT_quote then
									index_buffer.extend (index - 1) -- value upper
									next_token_index := advance (index); closed := True
							else
								index := advance (index)
							end
						when BT_apostrophe then
							inspect opening_quote
								when BT_apostrophe then
									index_buffer.extend (index - 1) -- value_upper
									next_token_index := advance (index); closed := True
							else
								index := advance (index)
							end
						when BT_ampersand then
							Result := scan_ref (buf, advance (index), a_end)
							if Result > 0 then
								index := next_token_index; Result := 0
							else
								closed := True  -- partial or invalid; exit
							end
						when BT_lt then
							next_token_index := index; Result := Tok_invalid; closed := True
					else
						index := advance (index)
					end
				end
				if not closed and Result = 0 then
					Result := Tok_partial
				end
			elseif not done then
				Result := Tok_partial
			end
		ensure
			index_buffer_full: Result /= Tok_partial implies index_buffer.count = 4
		end

	scan_comment (buf: SPECIAL [CHARACTER]; start_index, a_end: INTEGER): INTEGER
			-- Deferred: implemented in XT_PI_COMMENT_SCANNER.
		require start_index <= a_end
		deferred
		end

	scan_pi (buf: SPECIAL [CHARACTER]; start_index, a_end: INTEGER): INTEGER
			-- Deferred: implemented in XT_PI_COMMENT_SCANNER.
		require start_index <= a_end
		deferred
		end

	scan_cdata_section_open (buf: SPECIAL [CHARACTER]; start_index, a_end: INTEGER): INTEGER
			-- Deferred: implemented in XT_PI_COMMENT_SCANNER.
		require start_index <= a_end
		deferred
		end

feature {NONE} -- Internal attributes

	attribute_intervals_list: XT_STRING_INTERVALS

end