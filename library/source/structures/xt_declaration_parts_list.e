note
	description: "[
		List of parts for an ELEMENT or ATTLIST declaration
		
		For example:
			<!ATTLIST magic priority CDATA "50">
			
		would be:
			
			<< "magic", "priority", "CDATA", "50" >>
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-23 17:50:00 GMT (Sunday 23rd August 2026)"
	revision: "1"

class
	XT_DECLARATION_PARTS_LIST

inherit
	ARRAYED_LIST [STRING]
		rename
			make as make_sized,
			index_of as index_of_item
		export
			{NONE} all
		redefine
			new_filled_list, wipe_out
		end

	XT_TOKEN_CONSTANTS
		undefine
			copy, is_equal
		end

	XT_STRING_CONSTANTS
		undefine
			copy, is_equal
		end

	XT_PARSE_CONSTANTS
		export
			{ANY} Valid_declaration_types
		undefine
			copy, is_equal
		end

	XT_STRING_8_ROUTINES_I
		undefine
			copy, is_equal
		end

create
	make

feature -- Initialization

	make (a_name_cache: like name_cache)
		do
			make_sized (11)
			name_cache := a_name_cache
			create token_area.make_empty (area.capacity)
			create value_options.make (0)
		end

feature -- Status query

	defines_attribute_default: BOOLEAN
		-- `True' if parts list defines a default value for an attribute
		local
			i, i_final: INTEGER
		do
			if count >= 3 and then token_area [count - 1] = Tok_literal and then area_v2 [count - 2] = CDATA then
				Result := True
				from i := 0; i_final := count - 3 until i = i_final or not Result loop
					Result := token_area [i] = Tok_name
					i := i + 1
				end
			end
		end

	is_valid: BOOLEAN
		do
			Result := count >= 2
		end

feature -- Basic operations

	extend_defaults_table (default_value_table: HASH_TABLE [ARRAYED_LIST [STRING], STRING])
		local
			default_values_list: ARRAYED_LIST [STRING]
		do
			if attached default_value_table [first] as list then
				default_values_list := list
			else
				create default_values_list.make (5)
				default_value_table.extend (default_values_list, first)
			end
			default_values_list.extend (i_th (2))
			default_values_list.extend (last)
		end

	set_document_type (formal_public_identifier, DTD_uri: STRING)
		local
			second: STRING
		do
			if count >= 3 then
				second := i_th (2)
				if Valid_external_id_list.has (second) then
					formal_public_identifier.share (i_th (3))
					if count = 4 and then second = PUBLIC then
						DTD_uri.share (last)
					end
				end
			end
		end

feature -- Element change

	extend_for (
		buffer: SPECIAL [CHARACTER_8]; start_index, end_index, token: INTEGER; newline_or_tab_found: BOOLEAN
	)
		require
			valid_range: start_index <= end_index + 1
		local
			i, colon_index: INTEGER; l_area: like area_v2; l_token_area: like token_area
			name: STRING
		do
			i := count + 1
			l_area := area_v2; l_token_area := token_area
			if i > l_area.capacity then
				l_area := l_area.aliased_resized_area (i + additional_space)
				l_token_area := l_token_area.aliased_resized_area (i + additional_space)
				area_v2 := l_area; token_area := l_token_area
			end
			inspect token
				when Tok_name, Tok_pound_name then
					if attached name_constant (buffer, start_index, end_index, token) as l_name then
						name := l_name
					else
						colon_index := index_of (buffer, ':', start_index, end_index)
						name := name_cache.item (buffer, start_index, end_index, colon_index.max (0))
					end
					inspect last_token
						when Tok_open_parenthesis then
							l_area.extend (name); l_token_area.extend (Tok_or)
							value_options.extend (name)

						when Tok_or then
							value_options.extend (name)

					else
						l_area.extend (name); l_token_area.extend (token)
					end

				when Tok_literal then
					l_area.extend (new_value (buffer, start_index, end_index, newline_or_tab_found))
					l_token_area.extend (token)
			else
			end
			last_token := token
		ensure
			OR_token_inserted: value_options.count = old value_options.count + 1 implies token_area [count - 1] = Tok_or
			value_options_incremented: token_area [count - 1] = Tok_or implies value_options.count = old value_options.count + 1
		end

	set_last_token (token: INTEGER)
		do
			last_token := token
		end

	wipe_out
		-- Remove all items.
		do
			Precursor
			token_area.wipe_out
			value_options.wipe_out
			last_token := 0
		end

feature {NONE} -- Implementation

	name_constant (buffer: SPECIAL [CHARACTER_8]; start_index, end_index, token: INTEGER): detachable STRING
		local
			i, i_final: INTEGER; name_array: SPECIAL [STRING]
		do
			inspect token when Tok_pound_name then
				name_array := Hash_names
			else
				name_array := Reserved_names
			end
			from i := 0; i_final := name_array.count until i = i_final or Result /= Void loop
				if same_characters (buffer, start_index, end_index, name_array [i]) then
					Result := name_array [i]
				else
					i := i + 1
				end
			end
		end

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (create {like name_cache}.make)
		end

	new_value (buffer: SPECIAL [CHARACTER_8]; start_index, end_index: INTEGER; newline_or_tab_found: BOOLEAN): STRING_8
		do
			Result := new_attribute_value (buffer, start_index, end_index, newline_or_tab_found)
		end

feature {NONE} -- Internal attributes

	last_token: INTEGER

	name_cache: XT_NAME_CACHE

	token_area: SPECIAL [INTEGER]

	value_options: ARRAYED_LIST [STRING]
		-- values in brackets separated by OR symbol |
		-- Eg. <!ATTLIST generic-icon name (application-x-executable | audio-x-generic)>

feature {NONE} -- Constants

	Hash_names: SPECIAL [STRING]
		once
			Result := (<< Hash_fixed, Hash_implied, Hash_required >>).area
		end

	Reserved_names: SPECIAL [STRING]
		once
			Result := (<< CDATA, PUBLIC, SYSTEM >>).area
		end

	Hash_fixed: STRING = "#FIXED"

	Hash_implied: STRING = "#IMPLIED"

	Hash_required: STRING = "#REQUIRED"

end
