note
	description: "${XT_DECLARATION_PARTS_LIST} for `<!ENTITY ..>' declarations"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-25 14:45:00 GMT (Monday 25rd August 2026)"
	revision: "1"

class
	XT_ENTITY_PARTS_LIST

inherit
	XT_DECLARATION_PARTS_LIST
		undefine
			extend_external_id, is_valid, make_external_id, try_set_external_id, wipe_out_external_id
		redefine
			is_reserved_first_letter, name_cache, new_value, Reserved_identifiers
		end

	XT_ENTITY_PARTS_I
		undefine
			copy, is_equal
		redefine
			has_unparsed_entity
		end

create
	make

feature -- Status query

	has_unparsed_entity: BOOLEAN
		-- For example:
		-- 	<!NOTATION gif SYSTEM "image/gif">
		-- 	<!ENTITY logo SYSTEM "logo.gif" NDATA gif>
		do
			if count = 3 then
				Result := i_th (2) = NDATA and then i_th_token (3) = Tok_name
			end
		end

	is_parameter: BOOLEAN = False

feature -- Basic operations

	extend_table (entity_table: XT_ENTITY_TABLE)
		do
			inspect count
				when 1 then
				-- &legal; referenced near end of document /usr/share/gnome/help/synaptic/C/synaptic.xml
				-- Defined as external: <!ENTITY legal SYSTEM "gpl.xml">
				-- Without putting into table there will be a %N missing in output compared to eXpat
					if has_system_id then
						entity_table.put (Empty_string, name)
					end

				when 2 then
					entity_table.put (last, name)

				when 3 then
					if has_system_id then
						entity_table.put (Empty_string, name)
					end

					if i_th (2) = NDATA and i_th_token (3) = Tok_name
						and then attached entity_table.inserted_name as entity_name
					then
					-- attempting to reference this name in document returns the `Error_binary_entity_ref' error
						entity_name.set_has_notation_tag
					end
			else
			end
		end

feature {NONE} -- Implementation

	new_value (
		buffer: SPECIAL [CHARACTER_8]; start_index, end_index: INTEGER; newline_or_tab_found: BOOLEAN
	): STRING_8
		do
			if newline_or_tab_found then
				Result := new_abnormal_string (buffer, start_index, end_index)
			else
				Result := new_substring (buffer, start_index, end_index)
			end
		end

feature {NONE} -- Implementation

	is_reserved_first_letter (c: CHARACTER): BOOLEAN
		do
			inspect c when 'N', 'P', 'S' then
				Result := True
			else
			end
		end

feature {NONE} -- Internal attributes

	name_cache: XT_ENTITY_NAME_CACHE

feature {NONE} -- Reserved identifiers

	Reserved_identifiers: SPECIAL [STRING]
		once
			Result := (<< NDATA, SYSTEM, PUBLIC >>).area
		end
end
