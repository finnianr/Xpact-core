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
			set_properties
		end

create
	make

feature -- Access

	to_string: detachable STRING
		do
			inspect count
				when 1, 3 then
				-- &legal; referenced near end of document /usr/share/gnome/help/synaptic/C/synaptic.xml
				-- Defined as external: <!ENTITY legal SYSTEM "gpl.xml">
				-- Without putting into table there will be a %N missing in output compared to eXpat
					if has_system_id then
						Result := Empty_string
					end

				when 2 then
					Result := last

			else
			end
		end

feature -- Status query

	is_parameter: BOOLEAN = False

feature -- Basic operations

	extend_table (table: XT_ENTITY_TABLE)
		do
			if attached to_string as str and then attached entity_name as l_name and then l_name.count > 0 then
				table.put (str, l_name)
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

	set_properties (a_name: XT_ENTITY_NAME)
		do
			Precursor (a_name)
			inspect count when 3 then
			-- For example:
			-- 	<!NOTATION gif SYSTEM "image/gif">
			-- 	<!ENTITY logo SYSTEM "logo.gif" NDATA gif>

				if i_th (2) = NDATA and then i_th_token (3) = Tok_name then
				-- attempting to reference this name in document returns the `Error_binary_entity_ref' error
					a_name.set_unparsed
				end
			else end
		end

feature {NONE} -- Internal attributes

	name_cache: XT_ENTITY_NAME_CACHE

feature {NONE} -- Reserved identifiers

	Reserved_identifiers: SPECIAL [STRING]
		once
			Result := (<< NDATA, SYSTEM, PUBLIC >>).area
		end
end
