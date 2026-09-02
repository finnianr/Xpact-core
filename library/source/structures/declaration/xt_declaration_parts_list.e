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
			first as name,
			extend as extend_list,
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
		rename
			NOTATION as NOTATION_
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

feature {NONE} -- Initialization

	make (a_name_cache: like name_cache)
		do
			make_sized (11)
			name_cache := a_name_cache
			create token_area.make_empty (area.capacity)
			create type.make (50)
		end

feature -- Access

	type: STRING
		-- see attribute_types note at end of class

	i_th_token (i: INTEGER): INTEGER
		require
			valid_index: valid_index (i)
		do
			Result := token_area [i - 1]
		end

feature -- Status query

	has_notation_data: BOOLEAN
		do
			Result := count >= 2 and then i_th (count - 1) = NDATA
		end

	is_public: BOOLEAN
		do
			Result := count >= 2 and then i_th (2) = PUBLIC
		end

	is_valid: BOOLEAN
		do
			Result := count >= 2
		end

feature -- Element change

	extend (buffer: SPECIAL [CHARACTER_8]; start_index, end_index, token: INTEGER; newline_or_tab_found: BOOLEAN)
		require
			valid_range: start_index <= end_index + 1
		local
			i: INTEGER; l_area: like area_v2; l_token_area: like token_area
			l_name: STRING; check_for_name: BOOLEAN
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
					inspect last_token
						when Tok_open_parenthesis then
							if l_area.count > 1 and l_area [l_area.count - 1] = NOTATION then
								type.append (NOTATION)
								i := l_area.count - 1
								l_area [i] := type
								l_token_area [i] := Tok_or
							else
								l_area.extend (type); l_token_area.extend (Tok_or)
							end
							type.append_character ('('); append_area (type, buffer, start_index, end_index)

						when Tok_or then
							type.append_character ('|'); append_area (type, buffer, start_index, end_index)

						when Tok_close_parenthesis then
							type.append_character (')')
							last_token := Tok_none
							check_for_name := True

					else
						check_for_name := True
					end
					if check_for_name then
						if attached name_constant (buffer, start_index, end_index, token) as constant then
							l_name := constant

						elseif count > 1 and l_area [count - 1] = NDATA then
							l_name := new_notation_name (buffer, start_index, end_index)
						else
							l_name := new_name (buffer, start_index, end_index)
						end
						l_area.extend (l_name); l_token_area.extend (token)
					end

				when Tok_literal then
					l_area.extend (new_value (buffer, start_index, end_index, newline_or_tab_found))
					l_token_area.extend (token)
			else
			end
			last_token := token
		ensure
			OR_token_inserted:
				(type.count > old type.count and type [type.count] /= ')') implies token_area [count - 1] = Tok_or
			valid_type_string: (token_area [count - 1] = Tok_or and then old last_token /= Tok_close_parenthesis)
					implies valid_type_ending (buffer, start_index, end_index, old type.count + 1)
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
			type.wipe_out
			last_token := Tok_none
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

	valid_type_ending (buffer: SPECIAL [CHARACTER_8]; start_index, end_index, type_start_index: INTEGER): BOOLEAN
		local
			ending: STRING; delimiter_index: INTEGER
		do
			ending := type.substring (type_start_index, type.count)
			if ending.count > 2 then
				delimiter_index := ending.last_index_of ('(', ending.count)
				delimiter_index := ending.last_index_of ('|', ending.count).max (delimiter_index)
				ending.remove_head (delimiter_index)

				Result := same_characters (buffer, start_index, end_index, ending)
			end
		end

feature {NONE} -- Factory

	new_name (buffer: SPECIAL [CHARACTER_8]; start_index, end_index: INTEGER): STRING_8
		local
			colon_index: INTEGER
		do
			colon_index := index_of (buffer, ':', start_index, end_index)
			Result := name_cache.item (buffer, start_index, end_index, colon_index.max (0))
		end

	new_notation_name (buffer: SPECIAL [CHARACTER_8]; start_index, end_index: INTEGER): STRING_8
		do
			Result := new_substring (buffer, start_index, end_index)
		end

	new_value (buffer: SPECIAL [CHARACTER_8]; start_index, end_index: INTEGER; newline_or_tab_found: BOOLEAN): STRING_8
		do
			Result := new_attribute_value (buffer, start_index, end_index, newline_or_tab_found)
		end

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (create {like name_cache}.make)
		end

feature {NONE} -- Internal attributes

	last_token: INTEGER

	name_cache: XT_NAME_CACHE

	token_area: SPECIAL [INTEGER]

feature {NONE} -- Constants

	Hash_names: SPECIAL [STRING]
		once
			Result := (<< Hash_fixed, Hash_implied, Hash_required >>).area
		end

	Reserved_names: SPECIAL [STRING]
		once
			Result := (<< CDATA, NDATA, NOTATION, PUBLIC, SYSTEM >>).area
		end

	Hash_fixed: STRING = "#FIXED"

	Hash_implied: STRING = "#IMPLIED"

	Hash_required: STRING = "#REQUIRED"

note
	attribute_types: "[

		Values that `att_type` (from XML_AttlistDeclHandler) can take, per the
		DTD AttType grammar (XML 1.0 S3.3.1):

			DTD declaration           | att_type string
			--------------------------+----------------------------
			CDATA                     | "CDATA"
			ID                        | "ID"
			IDREF                     | "IDREF"
			IDREFS                    | "IDREFS"
			ENTITY                    | "ENTITY"
			ENTITIES                  | "ENTITIES"
			NMTOKEN                   | "NMTOKEN"
			NMTOKENS                  | "NMTOKENS"
			(v1|v2|...)  (enumeration)| "(v1|v2|...)"
			NOTATION (n1|n2|...)      | "NOTATION(n1|n2|...)"

		* The 8 fixed-keyword forms above are exact, case-sensitive constants
			- that is the complete set; there is no "NOTATIONS" or other variant.
		* "NOTATION(...)" has NO space between "NOTATION" and "(" in the
			string expat delivers, even though the XML source usually writes
			"NOTATION (a|b)" with a space.
		* Enumeration and NOTATION are the only two variable-content forms;
			check att_type.item (1) = '(' for a plain enumeration, or
			att_type.starts_with ("NOTATION(") for a notation list; otherwise
			it is one of the 8 fixed keywords above.
	]"

end
