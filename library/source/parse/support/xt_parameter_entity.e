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
			valid_parts: parts_list.count >= 1
		do
			name := parts_list.name
			external_id_type := parts_list.external_id_type
			if attached parts_list.external_id_list as id_list and then id_list.count > 0 then
				value := id_list [id_list.count - 1]
			else
				value := parts_list.last
			end
		end

feature -- Access

	external_id_type: INTEGER

	name: STRING

	value: STRING

feature -- Status query

	is_external: BOOLEAN
		-- `True' if the entity is defined externally to document
		do
			Result := external_id_type > 0
		end

	is_open: BOOLEAN

feature -- Status change	

	close
		do
			is_open := False
		end

	open
		do
			is_open := True
		end

end
