note
	description: "[
		Parameter entity reference used in document type definition.
		
		See for example "%selectors;" in this definition:
		
			<!DOCTYPE xsl:stylesheet [
			<!ENTITY % selectors SYSTEM "db-selectors.mod">
			%selectors;
			]>

	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-17 04:40:00 GMT (Monday 17th August 2026)"
	revision: "1"
class
	XT_PARAMETER_ENTITY

inherit
	XT_STRING_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make (parts_list: XT_PARAMETER_ENTITY_PARTS_LIST)
		require
			valid_parts: parts_list.count >= 2
		local
			s: XT_STRING_8_ROUTINES
		do
			name := parts_list.first; external_id := s.Empty_string
			if parts_list.count = 3 and then attached parts_list [2] as id
				and then Valid_external_id_list.has (id)
			then
				external_id := id
			end
			value := parts_list.last
		end

feature -- Access

	external_id: STRING

	name: STRING

	value: STRING

feature -- Status query

	is_referenced: BOOLEAN

feature -- Status change	

	set_referenced
		do
			is_referenced := True
		end

end
