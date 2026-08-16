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
	XT_UTF_8_VALIDATION

	XT_TOKEN_CONSTANTS
		export
			{NONE} all
		end

	XT_STRING_CONSTANTS
		export
			{NONE} all
		end

	XT_STRING_8_ROUTINES_I
		export
			{XT_XML_PARSER_BASE} all
		end

feature -- Access

	last_colon_index: INTEGER

	next_token_index: INTEGER
		-- Index of the first byte after the token just scanned.
		-- Invalid if the last call returned Tok_none or Tok_partial.

	error_code: INTEGER

feature -- Status report

	newline_or_tab_found: BOOLEAN

feature {NONE} -- Implementation

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

	new_bt_name (index: INTEGER): STRING
		require
			valid_index: BT_names_list.valid_index (index + 1)
		do
			Result := BT_names_list [index + 1]
		end

feature {NONE} -- Internal attributes

	index_x4_buffer: SPECIAL [INTEGER]

	scanned_entity_buffer: ARRAYED_LIST [STRING]

	attribute_intervals: XT_ATTRIBUTE_BUFFER_INTERVALS
		-- collected attribute name-value pair indices into `buffer'

	bad_char_index: INTEGER
			-- Set by `is_public_id' on failure: index of the bad character.

end
