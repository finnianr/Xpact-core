note
	description: "[
		${XT_DECLARATION_PARTS_LIST} for ENTITY parameter declarations with percent symbol.
		
		Example:
		
			<!ENTITY % selectors SYSTEM "../common/db-selectors.mod">
		
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-25 16:20:00 GMT (Monday 25rd August 2026)"
	revision: "1"

class
	XT_PARAMETER_ENTITY_PARTS_LIST

inherit
	XT_DECLARATION_PARTS_LIST

create
	make

feature -- Basic operations

	extend_table (parameter_table: HASH_TABLE [XT_PARAMETER_ENTITY, STRING])
		require
			valid_list: is_valid
		do
			parameter_table.put (create {XT_PARAMETER_ENTITY}.make (Current, last), first)
		end

end
