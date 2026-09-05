note
	description: "${XT_DECLARATION_PARTS_LIST} for `<!ATTLIST ..>' declarations"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-26 09:34:00 GMT (Wednesday 26th August 2026)"
	revision: "1"

class
	XT_ATTRIBUTE_PARTS_LIST

inherit
	XT_DECLARATION_PARTS_LIST
		rename
			name as element_name
		redefine
			is_complete, is_valid, Reserved_names
		end

create
	make

feature -- Access

	name: STRING
		do
			if attached area_v2 as l_area and then l_area.valid_index (1) then
				Result := l_area [1]
			else
				Result := Empty_string
			end
		end

feature -- Status query

	defines_attribute_default: BOOLEAN
		-- `True' completed attribute defines a default value
		require
			completed: is_complete
		do
			Result := i_th_token (count) = Tok_literal
		end

	is_valid: BOOLEAN
		-- is syntactically legal expat input, one component (the element name foo),
		-- zero attribute definitions, but XML_AttlistDeclHandler simply never fires for it.
		do
			Result := count >= 1 and then token_area [0] = Tok_name
		end

	is_complete: BOOLEAN
		-- `True' if list is completed and therefore ready for calling `on_close_declaration'
		do
			-- to get even one XML_AttlistDeclHandler call, you need all 4: element name, attribute name,
			-- AttType, and DefaultDecl. There's no 3-component form that fires it: drop any one and you
			-- either get a syntax error (per the state-machine trace above) or, in the zero-attribute-defs
			-- case (<!ATTLIST foo>), no attribute to report at all, so the handler simply never runs.
			inspect state when State_extending then
				inspect count
					when 4 then
						if token_area.filled_with (Tok_name, 0, 1) then
							if i_th (4) = Hash_fixed then
								Result := False

							elseif i_th_token (3) = Tok_or and then i_th (3).starts_with (NOTATION) then
								-- <!ATTLIST doc format NOTATION (gif|jpg|png) #IMPLIED>
								inspect i_th_token (4) when Tok_pound_name, Tok_literal then
									Result := True
								else end
							else
								inspect i_th_token (4)
									when Tok_pound_name then
									-- <!ATTLIST delegate command CDATA #REQUIRED>
										Result := i_th_reserved (3)

									when Tok_literal then
									-- <!ATTLIST magic priority CDATA "50">
										Result := i_th_reserved (3)
								else
								end
							end
						end
					when 5 then
						if token_area.filled_with (Tok_name, 0, 1) and then i_th_reserved (3) then
							-- <!ATTLIST delegate xmlns CDATA #FIXED ''>
							Result := i_th (4) = Hash_fixed and then i_th_token (5) = Tok_literal
						end
				else end
			else end
		end

	is_required: BOOLEAN
		require
			valid_list: is_valid
		do
			if attached area_v2 [3] as l_name then
				Result := l_name = Hash_fixed or else l_name = Hash_required
			end
		end

feature -- Element change

	partial_wipe_out
		local
			l_name: STRING
		do
			l_name := element_name
			wipe_out
			area.extend (l_name); token_area.extend (Tok_name)
		end

feature {NONE} -- Constants

	Reserved_names: SPECIAL [STRING]
		once
			Result := (<< CDATA, ID, IDREF, IDREFS, ENTITY, ENTITIES, NMTOKEN, NMTOKENS, NOTATION >>).area
		end

end
