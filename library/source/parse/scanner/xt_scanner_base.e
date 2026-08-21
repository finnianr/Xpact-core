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

feature {NONE} -- Initialisation

	make
		do
			create scanned_entity_buffer.make (5)
			create index_x4_buffer.make_empty (4)
			create attribute_list.make (11)
			name_cache := attribute_list.name_cache
			entity_cache := attribute_list.entity_cache
			entity_table := attribute_list.entity_table
		end

feature -- Access

	last_colon_index: INTEGER

	next_token_index: INTEGER
		-- Index of the first byte after the token just scanned.
		-- Invalid if the last call returned Tok_none or Tok_partial.

feature -- Status report

	newline_or_tab_found: BOOLEAN

feature -- Element change

	reset
		do
			attribute_list.set_permit_undefined_entities (False)
			attribute_list.wipe_out
			entity_cache.reset
			name_cache.reset
			entity_table.wipe_out
			entity_table.set_predefined (entity_cache)
		end

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

	attribute_list: XT_ATTRIBUTE_LIST
		-- collected attribute name-value pair indices into `buffer'

	entity_table: XT_ENTITY_TABLE
		-- table of expanded entities defined in DOCTYPE by ENTITY

	entity_cache: XT_ENTITY_NAME_CACHE
		-- efficient lookup of entity names from character buffer interval

	name_cache: XT_NAME_CACHE
		-- efficient lookup of tag names

	index_x4_buffer: SPECIAL [INTEGER]

	scanned_entity_buffer: ARRAYED_LIST [XT_ENTITY_NAME]

	scanned_error_code: INTEGER

	bad_char_index: INTEGER
			-- Set by `is_public_id' on failure: index of the bad character.

end
