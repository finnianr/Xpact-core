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
		  MINBPC(enc)               -> min_bytes_per_char
		  HAS_CHAR(enc, p, end)     -> index < end_index   (written inline)
		  HAS_CHARS(enc, p, end, n) -> end_index - index >= n * min_bytes_per_char
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

deferred class XT_SCANNER_HELPERS

inherit
	XT_BYTE_TYPE_CONSTANTS; XT_TOKEN_CONSTANTS; XT_STRING_CONSTANTS

	XT_STRING_ROUTINES_I
		export
			{XT_XML_PARSER_BASE} all
		end

feature -- Multi-byte name-character checks

-- UTF-8; deferred for UTF-16/etc.
-- never called for single-byte encoding

	is_name_char_2 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
			-- True when the 2-byte UTF-8 sequence at index is an XML name character.
		require
			valid_index: index + 1 < buf.count
		do
			Result := False
		end

	is_name_char_3 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
			-- True when the 3-byte UTF-8 sequence at index is an XML name character.
		require
			valid_index: index + 2 < buf.count
		do
			Result := False
		end

	is_name_char_4 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
			-- True when the 4-byte UTF-8 sequence at index is an XML name character.
		require
			valid_index: index + 3 < buf.count
		do
			Result := False
		end

	is_name_start_char_2 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
			-- True when the 2-byte UTF-8 sequence at index can start an XML name.
		require
			valid_index: index + 1 < buf.count
		do
			Result := False
		end

	is_name_start_char_3 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
		require
			valid_index: index + 2 < buf.count
		do
			Result := False
		end

	is_name_start_char_4 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
		require
			valid_index: index + 3 < buf.count
		do
			Result := False
		end

	is_invalid_char_2 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
			-- True when the 2-byte sequence at index is not a valid Unicode scalar.
		require
			valid_index: index + 1 < buf.count
		do
			Result := False
		end

	is_invalid_char_3 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
		require
			valid_index: index + 2 < buf.count
		do
			Result := False
		end

	is_invalid_char_4 (buf: SPECIAL [CHARACTER]; index: INTEGER): BOOLEAN
		require
			valid_index: index + 3 < buf.count
		do
			Result := False
		end

feature {NONE} -- Implementation

	advance (index: INTEGER): INTEGER
			-- index + min_bytes_per_char  (replaces index += MINBPC)
		do
			Result := index + char_width
		end

	character_count (count: INTEGER): INTEGER
		-- left shift by 1 in UTF-16 descendant
		do
			Result := count
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
			-- end_index - index >= count * min_bytes_per_char  (HAS_CHARS macro)
		do
			Result := end_index - index >= character_count (count)
		end


	offset_by (index, offset: INTEGER): INTEGER
		do
			Result := index + offset
		end

	prune_carriage_returns (buf: SPECIAL [CHARACTER]; CR_index, quote_index, CR_count: INTEGER)
		-- prune %R in attribute value by doing a left shift and filling in with spaces at the end
		require
			valid_cr_index: buf [CR_index] = '%R'
			valid_quote_index: buf [quote_index] = '"' or buf [quote_index] = '%''
		local
			i, j: INTEGER
		do
			from i := CR_index; j := CR_index until i > quote_index loop
				inspect buf [i] when '%R' then
					i := advance (i)
				else
					buf [j] := buf [i]
					j := advance (j)
					i := advance (i)
				end
			end
		-- paint over remaining characters with spaces
			from until j > quote_index loop
				buf [j] := ' '
				j := advance (j)
			end
		end

feature {NONE} -- Internal attributes

	next_token_index: INTEGER

	index_x4_buffer: SPECIAL [INTEGER]

	scanned_entity_buffer: ARRAYED_LIST [STRING]

feature {XT_XML_PARSER_BASE} -- Deferred

	char_width: INTEGER
		deferred
		ensure positive: Result >= 1
		end

	byte_type_table: SPECIAL [INTEGER]
		-- 256-entry table mapping each byte value to its BT_* type.
		deferred
		end

	attribute_intervals: XT_ATTRIBUTE_BUFFER_INTERVALS
		-- collected attribute name-value pair indices into `buffer'
		deferred
		end

end
