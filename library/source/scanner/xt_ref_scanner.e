note
	description: "[
		Scanner for XML references: entity refs (&name;) and character
		refs (&#NNN; and &#xHHH;).

		All three features correspond to static functions in xmltok_impl.c:
		  scan_ref        <- scanRef
		  scan_char_ref   <- scanCharRef
		  scan_hex_char_ref <- scanHexCharRef

		Entry points: index is positioned one byte PAST the sigil
		  scan_ref      : past '&'
		  scan_char_ref  : past '&#'
		  scan_hex_char_ref: past '&#x'
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 20:31:47 GMT (Saturday 20th June 2026)"
	revision: "1"

deferred class XT_REF_SCANNER

inherit
	XT_SCANNER_HELPERS

feature {NONE} -- Reference scanning

	scan_ref (buf: SPECIAL [CHARACTER]; entity_buffer: LIST [STRING]; start_index, end_index: INTEGER): INTEGER
			-- Scan entity or character reference after '&'.
			-- Sets next_token_ptr.  Returns Tok_entity_ref, Tok_char_ref, or error.
		require
			valid_range: start_index <= end_index
		local
			index: INTEGER
		do
			index := start_index
			if index >= end_index then
				Result := Tok_partial
			elseif attached byte_type_table as bt_table then
				inspect bt_table [buf [index].code].to_integer_32
					when BT_hash then
						Result := scan_char_ref (buf, entity_buffer, advance (index), end_index)
					when BT_name_start, BT_hex_digit then
						index := advance (index)
						from until index >= end_index loop
							inspect bt_table [buf [index].code].to_integer_32
								when BT_name_start, BT_hex_digit, BT_digit, BT_name_only, BT_minus then
									index := advance (index)
								when BT_semicolon then
									next_token_index := advance (index)
									entity_buffer.extend (entity_cache.item (buf, start_index, index - 1))
									Result := Tok_entity_ref
									index := end_index  -- exit loop
								else
									next_token_index := index
									Result := Tok_invalid
									index := end_index  -- exit loop
								end
						end
						if Result = 0 then
							Result := Tok_partial
						end
					when BT_lead_2_byte then
						if end_index - index >= 2 and then not is_invalid_char_2 (buf, index)
							and then is_name_start_char_2 (buf, index)
						then
							index := index + 2
							Result := scan_ref_name_tail (buf, index, end_index)
						else
							next_token_index := index
							Result := Tok_invalid
						end
					when BT_lead_3_byte then
						if end_index - index >= 3 and then not is_invalid_char_3 (buf, index)
							and then is_name_start_char_3 (buf, index)
						then
							index := index + 3
							Result := scan_ref_name_tail (buf, index, end_index)
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

	scan_char_ref (buf: SPECIAL [CHARACTER]; entity_buffer: LIST [STRING]; start_index, end_index: INTEGER): INTEGER
			-- Scan character reference after '&#'.  Returns Tok_char_ref or error.
		require start_index <= end_index
		local
			index: INTEGER
		do
			index := start_index
			if index >= end_index then
				Result := Tok_partial
			elseif buf [index] = 'x' then
				Result := scan_hex_char_ref (buf, entity_buffer, advance (index), end_index)

			elseif attached byte_type_table as bt_table then
				inspect bt_table [buf [index].code].to_integer_32
					when BT_digit then
						index := advance (index)
						from until index >= end_index loop
							inspect bt_table [buf [index].code].to_integer_32
								when BT_digit then
									index := advance (index)
								when BT_semicolon then
									next_token_index := advance (index)
									entity_buffer.extend (entity_cache.item (buf, start_index - 1, index - 1))
									Result := Tok_char_ref
									index := end_index
							else
								next_token_index := index
								Result := Tok_invalid
								index := end_index
							end
						end
						if Result = 0 then
							Result := Tok_partial
						end
				else
					next_token_index := index
					Result := Tok_invalid
				end
			end
		end

	scan_hex_char_ref (buf: SPECIAL [CHARACTER]; entity_buffer: LIST [STRING]; start_index, end_index: INTEGER): INTEGER
			-- Scan hex character reference after '&#x'.  Returns Tok_char_ref or error.
		require start_index <= end_index
		local
			index, bt: INTEGER
		do
			index := start_index
			if index >= end_index then
				Result := Tok_partial

			elseif attached byte_type_table as bt_table then
				bt := bt_table [buf [index].code].to_integer_32
				if bt = BT_digit or bt = BT_hex_digit then
					index := advance (index)
					from until index >= end_index loop
						bt := bt_table [buf [index].code].to_integer_32
						if bt = BT_digit or bt = BT_hex_digit then
							index := advance (index)
						elseif bt = BT_semicolon then
							next_token_index := advance (index)
							entity_buffer.extend (entity_cache.item (buf, start_index - 2, index - 1))
							Result := Tok_char_ref
							index := end_index
						else
							next_token_index := index
							Result := Tok_invalid
							index := end_index
						end
					end
					if Result = 0 then
					Result := Tok_partial
				end
				else
					next_token_index := index
					Result := Tok_invalid
				end
			end
		end

feature {NONE} -- Reference sub-helper

	scan_ref_name_tail (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
			-- Continue scanning after a valid nmstrt multi-byte start.
		local
			index: INTEGER
		do
			index := start_index
			if attached byte_type_table as bt_table then
				from until index >= end_index loop
					inspect bt_table [buf [index].code].to_integer_32
						when BT_name_start, BT_hex_digit, BT_digit, BT_name_only, BT_minus then
							index := advance (index)
						when BT_semicolon then
							next_token_index := advance (index)
							Result := Tok_entity_ref
							index := end_index
					else
						next_token_index := index
						Result := Tok_invalid
						index := end_index
					end
				end
			end
			if Result = 0 then
				Result := Tok_partial
			end
		end

feature {NONE} -- Internal attributes

	name_cache: XT_NAME_CACHE
		-- efficient lookup of attribute/tag names from character buffer interval

	entity_cache: XT_ENTITY_NAME_CACHE
		-- efficient lookup of entity names from character buffer interval

	attribute_intervals: XT_ATTRIBUTE_BUFFER_INTERVALS

	scanned_entity_buffer: ARRAYED_LIST [STRING]

end
