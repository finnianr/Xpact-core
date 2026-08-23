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
			index_of as index_of_item
		export
			{NONE} all
		redefine
			make, wipe_out
		end

	XT_TOKEN_CONSTANTS
		undefine
			copy, is_equal
		end

	XT_STRING_CONSTANTS
		export
			{NONE} all
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

	make (n: INTEGER)
		do
			Precursor (n)
			create token_area.make_empty (n)
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

	extend_defaults_table (default_value_table: HASH_TABLE [ARRAYED_LIST [STRING], STRING])
		local
			default_values_list: ARRAYED_LIST [STRING]; colon_index: INTEGER
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

feature -- Element change

	extend_for (
		buffer: SPECIAL [CHARACTER_8]; start_index, end_index, token: INTEGER; name_cache: XT_NAME_CACHE
		newline_or_tab_found: BOOLEAN
	)
		local
			i, i_final, colon_index: INTEGER; l_area: like area_v2; l_token_area: like token_area
			name: STRING; found_name: BOOLEAN
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
					name := Empty_string
					from i := 0; i_final := Reserved_names.count until i = i_final or found_name loop
						name := Reserved_names [i]
						if same_characters (buffer, start_index, end_index, name) then
							found_name := True
						else
							i := i + 1
						end
					end
					if not found_name then
						colon_index := index_of (buffer, ':', start_index, end_index)
						name := name_cache.item (buffer, start_index, end_index, colon_index.max (0))
					end
					l_area.extend (name)
					l_token_area.extend (token)

				when Tok_literal then
					l_area.extend (new_attribute_value (buffer, start_index, end_index, newline_or_tab_found))
					l_token_area.extend (token)
			else
			end
		end

	wipe_out
		-- Remove all items.
		do
			Precursor
			token_area.wipe_out
		end

feature {NONE} -- Internal attributes

	token_area: SPECIAL [INTEGER]

feature {NONE} -- Constants

	Reserved_names: SPECIAL [STRING]
		once
			Result := (<< CDATA, Hash_fixed, Hash_implied, Hash_required >>).area
		end

	Hash_fixed: STRING = "#FIXED"

	Hash_implied: STRING = "#IMPLIED"

	Hash_required: STRING = "#REQUIRED"

end
