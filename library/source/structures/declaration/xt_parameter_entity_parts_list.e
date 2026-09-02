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
			is_valid
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

feature -- Factory

	new_parameter: XT_PARAMETER_ENTITY
		do
			create Result.make (Current)
		end

feature {NONE} -- Implementation

	new_name (buffer: SPECIAL [CHARACTER_8]; start_index, end_index: INTEGER): STRING_8
		do
			Result := name_cache.item (buffer, start_index, end_index)
		end

feature {NONE} -- Internal attributes

	name_cache: XT_PARAMETER_ENTITY_NAME_CACHE

end
