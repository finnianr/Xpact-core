note
	description: "[
		${XT_DECLARATION_PARTS_LIST} for `<!ENTITY % ..>' declarations
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-16 13:40:00 GMT (Saturday 16th August 2026)"
	revision: "1"

class
	XT_PARAMETER_ENTITY_PARTS_LIST

inherit
	XT_DECLARATION_PARTS_LIST
		undefine
			extend_external_id, is_valid, make_external_id, try_set_external_id, wipe_out_external_id
		redefine
			name_cache, new_name
		end

	XT_ENTITY_PARTS_I
		undefine
			copy, is_equal
		end

create
	make

feature -- Status query

	is_parameter: BOOLEAN = True

feature -- Basic operations

	extend_table (table: HASH_TABLE [STRING, XT_ENTITY_NAME])
		do
			if attached entity_name as l_name and then l_name.count > 0 then
				if entity_name.has_external_id then
					table.put (Empty_string, l_name)
				else
					table.put (last, l_name)
				end
			end
		end

feature {NONE} -- Implementation

	new_name (buffer: SPECIAL [CHARACTER_8]; start_index, end_index: INTEGER): like name_cache.item
		do
			Result := name_cache.item (buffer, start_index, end_index)
		end

feature {NONE} -- Internal attributes

	name_cache: XT_PARAMETER_ENTITY_NAME_CACHE

end
