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
	XT_SCANNER_BASE

	XT_REF_SCANNER

feature -- Measurement

	tag_name_count: INTEGER

	tag_name (name_cache: XT_NAME_CACHE; buffer: SPECIAL [CHARACTER_8]; lt_index: INTEGER): STRING_8
		require
			last_colon_index_valid: last_colon_index_valid (buffer, lt_index)

		local
			start_index: INTEGER
		do
			start_index := lt_index + 1
			Result := name_cache.item (buffer, start_index, start_index + tag_name_count - 1, last_colon_index)
		ensure
			same_tag_length: Result.count = name_count (buffer, lt_index + 1)
		end

feature -- Contract support

	last_colon_index_valid (buffer: SPECIAL [CHARACTER_8]; lt_index: INTEGER): BOOLEAN
		local
			index_colon: INTEGER
		do
			if attached new_substring (buffer, lt_index + 1, lt_index + tag_name_count) as str then
				index_colon := str.index_of (':', 1)
				if index_colon = 0 then
					Result := last_colon_index = 0
				else
					Result := index_colon + lt_index = last_colon_index
				end
			end
		end

feature {NONE} -- Tag scanning

	scan_lt (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
			-- Dispatch on the character after '<'.
			-- Returns the appropriate XML_TOK_* code; sets next_token_ptr.
		require
			valid_range: start_index <= end_index
		local
			index, bt_code, byte_count: INTEGER
		do
			index := start_index
			if index >= end_index then
				Result := Tok_partial
			else
				bt_code := bt_table [buf [index].code]
				inspect bt_code
					when BT_exclamation then
						index := index + 1
						if index >= end_index then
							Result := Tok_partial
						else
							inspect bt_table [buf [index].code]
								when BT_minus then
									Result := scan_comment (buf, index + 1, end_index, bt_table)
								when BT_left_square_bracket then
									Result := scan_cdata_section_open (buf, index + 1, end_index)
							else
								next_token_index := index
								Result := Tok_invalid
							end
						end
					when BT_question then
						Result := scan_pi (buf, index + 1, end_index, bt_table)

					when BT_forward_slash then
						Result := scan_end_tag (buf, index + 1, end_index, bt_table)

					when BT_name_start, BT_hex_digit then
						index := index + 1
						Result := scan_start_tag_name (buf, index, end_index, 1, bt_table)

					when BT_lead_2_byte, BT_lead_3_byte, BT_lead_4_byte then
						byte_count := bt_code - 3
						if end_index - index < byte_count then
							Result := Tok_partial_char

						elseif is_invalid_character (buf, index, byte_count) then
							next_token_index := index
							Result := Tok_invalid
						else
							index := index + byte_count
							Result := scan_start_tag_name (buf, index, end_index, byte_count, bt_table)
						end
				else
					next_token_index := index
					Result := Tok_invalid
				end
			end
		end

	scan_end_tag (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
			-- Scan end tag after '</'.  Returns Tok_end_tag or error.
		require
			valid_range: start_index <= end_index
		local
			index, name_lower, name_upper, bt_code, byte_count, l_last_colon_index: INTEGER; done: BOOLEAN
		do
			index := start_index; name_lower := start_index; name_upper := Unset
			if index >= end_index then
				Result := Tok_partial
			else
				bt_code := bt_table [buf [index].code]
				inspect bt_code
					when BT_name_start, BT_hex_digit then
						index := index + 1

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

				else
					next_token_index := index; Result := Tok_invalid; done := True
				end
				if not done then
					from until index >= end_index or done loop
						bt_code := bt_table [buf [index].code]
						inspect bt_code
							when BT_name_start, BT_hex_digit, BT_digit, BT_name_only, BT_minus then
								index := index + 1

							when BT_colon then
								l_last_colon_index := index
								index := index + 1

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

							when BT_whitespace, BT_CR, BT_LF then
								inspect name_upper when Unset then
									name_upper := index - 1
								else end
								index := index + 1
								from until index >= end_index or done loop
									inspect bt_table [buf [index].code]
										when BT_whitespace, BT_CR, BT_LF then
											index := index + 1
										when BT_gt then
											next_token_index := index + 1
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
								inspect name_upper when Unset then
									name_upper := index - 1
								else end
								next_token_index := index + 1
								Result := Tok_end_tag
								done := True
						else
							next_token_index := index
							Result := Tok_invalid
							done := True
						end
					end
					if done then
						tag_name_count := name_upper - name_lower + 1
						last_colon_index := l_last_colon_index
					else
						Result := Tok_partial
					end
				end
			end
		end

	scan_attributes (
		buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]
		attributes: XT_ATTRIBUTE_BUFFER_INTERVALS

	): INTEGER
		-- Scan attribute list starting at the first attribute name character.
		-- Returns Tok_start_tag_with_atts, Tok_empty_element_with_atts, or error.
		require
			valid_range: start_index <= end_index
		local
			index, bt_code, byte_count, l_last_colon_index, error: INTEGER; done: BOOLEAN
			index_buffer: SPECIAL [INTEGER]; entity_buffer: like scanned_entity_buffer
		do
			index := start_index; index_buffer := index_x4_buffer
			entity_buffer := scanned_entity_buffer
			index_buffer.extend (index + buf [index].is_space.to_integer) -- name lower
			from until index >= end_index or done loop
				bt_code := bt_table [buf [index].code]
				inspect bt_code
					when BT_name_start, BT_hex_digit, BT_digit, BT_name_only, BT_minus then
						inspect append_name_lower (buf, index_buffer, index) when Tok_invalid then
							Result := Tok_invalid; done := True
						else end
						index := index + 1

					when BT_colon then
						l_last_colon_index := index
						index := index + 1

					when BT_lead_2_byte, BT_lead_3_byte, BT_lead_4_byte then
						byte_count := bt_code - 3
						if end_index - index < byte_count then
							Result := Tok_partial_char; done := True

						elseif is_invalid_character (buf, index, byte_count) then
							next_token_index := index
							Result := Tok_invalid; done := True
						else
							inspect append_name_lower (buf, index_buffer, index) when Tok_invalid then
								Result := Tok_invalid; done := True
							else end
							index := index + byte_count
						end

					when BT_whitespace, BT_CR, BT_LF then
					-- Skip one whitespace byte; outer loop handles subsequent chars naturally.
					-- Whitespace may separate a name from '=' or one attribute from the next.
						inspect index_buffer.count when 1 then
							index_buffer.extend (index - 1) -- name upper
						else end
						index := index + 1

					when BT_equals then
						inspect index_buffer.count
							when 1 then
								index_buffer.extend (index - 1) -- name upper
						else end
						index := index + 1
						Result := scan_attribute_value (buf, index, end_index, bt_table, index_buffer, entity_buffer)
						inspect Result
							when Tok_partial, Tok_partial_char then
								attributes.wipe_out; index_buffer.wipe_out; entity_buffer.wipe_out
						else
							inspect index_buffer.count when 4 then
								error := attributes.transfer (buf, index_buffer, l_last_colon_index, entity_buffer)
								inspect error when 0 then
									do_nothing
								else
									error_code := error
									Result := tok_start_tag_with_attributes.opposite; done := True
								end
							else
								index_buffer.wipe_out
							end
						end
						if Result /= 0 then
							done := True
						else
							index := next_token_index
						end
					when BT_gt then
						next_token_index := index + 1
						inspect index_buffer.count when 2 then
						-- Eg. class="win-textbox win-textbox-PuaCompatible-font" autofocus />
							Result := Tok_invalid
						else
							Result := tok_start_tag_with_attributes
						end
						done := True

					when BT_forward_slash then
						index := index + 1
						if index_buffer.count = 2 then
						-- Eg.class="win-textbox win-textbox-PuaCompatible-font" autofocus />
							Result := Tok_invalid; done := True

						elseif index >= end_index then
							-- seen '/' but '>' not yet in buffer; all transferred attrs must be cleared
							attributes.wipe_out; index_buffer.wipe_out; entity_buffer.wipe_out
							Result := Tok_partial; done := True

						elseif buf [index] = '>' then
							next_token_index := index + 1
							Result := tok_empty_element_with_attributes
							done := True
						else
							next_token_index := index; Result := Tok_invalid; done := True
						end
				else
					next_token_index := index; Result := Tok_invalid; done := True
				end
			end
			if done then
				inspect Result when Tok_invalid then
					attributes.wipe_out; index_x4_buffer.wipe_out
				else end
			else
				Result := Tok_partial
				attributes.wipe_out; index_x4_buffer.wipe_out
			end
		ensure
			attribute_intervals_valid_count:
				Result /= Tok_partial implies attributes.is_valid_count
		end

feature {NONE} -- Tag sub-helpers

	scan_start_tag_name (buf: SPECIAL [CHARACTER]; start_index, end_index, lead_count: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
		-- After consuming name-start char(s); scan rest of start tag name.
		local
			index, name_lower, name_upper, byte_count, bt_code, l_last_colon_index: INTEGER; done: BOOLEAN
		do
			index := start_index; name_lower := start_index - lead_count; name_upper := Unset
			from until index >= end_index or done loop
				bt_code := bt_table [buf [index].code]
				inspect bt_code
					when BT_name_start, BT_hex_digit, BT_digit, BT_name_only, BT_minus then
						index := index + 1

					when BT_colon then
						l_last_colon_index := index
						index := index + 1

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
					when BT_whitespace, BT_CR, BT_LF then
						inspect name_upper when Unset then
							name_upper := index - 1
						else end
						index := index + 1
						from until index >= end_index or done loop
							inspect bt_table [buf [index].code]
								when BT_name_start, BT_hex_digit, BT_lead_2_byte, BT_lead_3_byte, BT_lead_4_byte then
									Result := scan_attributes (buf, index, end_index, bt_table, attribute_intervals); done := True
								when BT_gt then
									next_token_index := index + 1
									Result := tok_start_tag_no_attributes; done := True
								when BT_forward_slash then
									index := index + 1
									if index >= end_index then
										Result := Tok_partial; done := True
									elseif buf [index] = '>' then
										next_token_index := index + 1
										Result := tok_empty_element_no_attributes; done := True
									else
										next_token_index := index; Result := Tok_invalid; done := True
									end
								when BT_whitespace, BT_CR, BT_LF then
									index := index + 1
							else
								next_token_index := index; Result := Tok_invalid; done := True
							end
						end
						if not done then
							Result := Tok_partial; done := True
						end
					when BT_gt then
						inspect name_upper when Unset then
							name_upper := index - 1
						else end
						next_token_index := index + 1
						Result := tok_start_tag_no_attributes; done := True

					when BT_forward_slash then
						inspect name_upper when Unset then
							name_upper := index - 1
						else end
						index := index + 1
						if index >= end_index then
							Result := Tok_partial; done := True
						elseif buf [index] = '>' then
							next_token_index := index + 1
							Result := tok_empty_element_no_attributes; done := True
						else
							next_token_index := index; Result := Tok_invalid; done := True
						end
				else
					next_token_index := index; Result := Tok_invalid; done := True
				end
			end
			if done then
				tag_name_count := name_upper - name_lower + 1
				last_colon_index := l_last_colon_index
			else
				Result := Tok_partial
			end
		end

	scan_attribute_value (
		buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER
		bt_table: SPECIAL [INTEGER]; lower_upper: SPECIAL [INTEGER]; entity_buffer: LIST [STRING];
	): INTEGER
			-- Scan past whitespace to the opening quote, then the value up to matching
			-- close quote.  Sets next_token_ptr past the closing quote.
			-- Returns 0 (caller should continue) or a non-zero error/end token code.
		local
			index, opening_quote, byte_count, bt_code: INTEGER; done, closed: BOOLEAN
		do
			index := start_index
			-- skip to opening quote
			from until index >= end_index or done loop
				inspect bt_table [buf [index].code]
					when BT_quote then
						opening_quote := BT_quote; done := True
					when BT_apostrophe then
						opening_quote := BT_apostrophe; done := True
					when BT_whitespace, BT_LF, BT_CR then
						index := index + 1
				else
					next_token_index := index; Result := Tok_invalid; done := True
				end
			end
			if done and Result = 0 then
			-- scan value content up to matching closing quote
				index := index + 1  -- skip opening quote
				lower_upper.extend (index)
				from until index >= end_index or closed loop
					bt_code := bt_table [buf [index].code]
					inspect bt_code
						when BT_quote then
							inspect opening_quote
								when BT_quote then
									lower_upper.extend (index - 1)
									next_token_index := index + 1; closed := True
							else
								index := index + 1
							end
						when BT_apostrophe then
							inspect opening_quote
								when BT_apostrophe then
									lower_upper.extend (index - 1)
									next_token_index := index + 1; closed := True
							else
								index := index + 1
							end
						when BT_ampersand then
							Result := scan_ref (buf, Tok_attribute_value_s, index + 1, end_index, bt_table, entity_buffer)
							if Result > 0 then
								index := next_token_index; Result := 0
							else
								closed := True  -- partial or invalid; exit
							end
						when BT_lt then
							next_token_index := index; Result := Tok_invalid; closed := True

						when BT_LF, BT_CR then
							attribute_intervals.report_newline_or_tab
							index := index + 1

						when BT_whitespace then
							inspect buf [index] when '%T' then
								attribute_intervals.report_newline_or_tab
							else end
							index := index + 1

						when BT_non_xml, BT_malform, BT_continuation_byte then
							next_token_index := index; Result := Tok_invalid; closed := True

						when BT_lead_2_byte, BT_lead_3_byte, BT_lead_4_byte then
							byte_count := bt_code - 3
							if end_index - index < byte_count then
								Result := Tok_partial_char; closed := True

							elseif is_invalid_character (buf, index, byte_count) then
								next_token_index := index
								Result := Tok_invalid; closed := True
							else
								index := index + byte_count
							end
					else
						index := index + 1
					end
				end
				if not closed and Result = 0 then
					Result := Tok_partial
				end
			elseif not done then
				Result := Tok_partial
			end
		end

feature {NONE} -- Contract support

	name_count (buf: SPECIAL [CHARACTER]; start_index: INTEGER): INTEGER
		-- Byte count of the XML name starting at start_index.
		-- Stops at first byte whose type is not a name-continuation type.
		require
			valid_start_index: start_index >= 0
		local
			index: INTEGER; done: BOOLEAN
		do
			if attached byte_type_table as bt_table then
				from index := start_index until index >= buf.count or done loop
					inspect bt_table [buf [index].code]
						when Bt_lead_2_byte then
							index := index + 2

						when Bt_lead_3_byte then
							index := index + 3

						when Bt_lead_4_byte then
							index := index + 4

						when BT_name_start, BT_name_only, BT_hex_digit, BT_digit, BT_minus, BT_colon then
							index := index + 1
					else
						done := True
					end
				end
			end
			Result := index - start_index
		ensure
			non_negative: Result >= 0
		end

feature {NONE} -- Implementation

	append_name_lower (buf: SPECIAL [CHARACTER]; index_buffer: SPECIAL [INTEGER]; index: INTEGER): INTEGER
		do
			Result := 1
			inspect index_buffer.count
				when 0 then
					index_buffer.extend (index + buf [index].is_space.to_integer) -- name lower
				when 2 then
				-- <div itemscope itemtype="http://schema.org/Type" for example
					Result := Tok_invalid
			else
			end
		end

feature {NONE} -- Deferred

	scan_comment (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
			-- Deferred: implemented in XT_PI_COMMENT_SCANNER.
		require
			valid_range: start_index <= end_index
		deferred
		end

	scan_pi (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
			-- Deferred: implemented in XT_PI_COMMENT_SCANNER.
		require
			valid_range: start_index <= end_index
		deferred
		end

	scan_cdata_section_open (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
			-- Deferred: implemented in XT_PI_COMMENT_SCANNER.
		require
			valid_range: start_index <= end_index
		deferred
		end

feature {NONE} -- Constants

	Unset: INTEGER = -1
end
