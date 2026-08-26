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
		redefine
			name_cache, new_value
		end

create
	make

feature -- Status query

	is_valid: BOOLEAN
		do
			Result := count >= 2
		end

feature -- Basic operations

	extend_table (entity_table: XT_ENTITY_TABLE)
		do
			inspect count
				when 2 then
					entity_table.put (last, first)
				when 3 then
				-- &legal; referenced near end of document /usr/share/gnome/help/synaptic/C/synaptic.xml
				-- Defined as external: <!ENTITY legal SYSTEM "gpl.xml">
				-- Without putting into table there will be a %N missing in output compared to eXpat
					entity_table.put (Empty_string, first)
			else
			end
		end

feature {NONE} -- Implementation

	new_value (buffer: SPECIAL [CHARACTER_8]; start_index, end_index: INTEGER; newline_or_tab_found: BOOLEAN): STRING_8
		do
			if newline_or_tab_found then
				create {XT_ABNORMAL_STRING} Result.make (buffer, start_index, end_index, newline_or_tab_found)
			else
				Result := new_attribute_value (buffer, start_index, end_index, newline_or_tab_found)
			end
		end

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (create {like name_cache}.make)
		end

feature {NONE} -- Internal attributes

	name_cache: XT_ENTITY_NAME_CACHE

end
