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
	STRING
		rename
			empty as is_string_empty,
			empty_area as new_empty_area,
			make as make_sized
		redefine
			make_sized
		end

	XT_STRING_CONSTANTS
		undefine
			copy, is_equal, out
		end

create
	make, make_sized

feature {NONE} -- Initialization

	make (parts_list: XT_PARAMETER_ENTITY_PARTS_LIST)
		require
			valid_parts: parts_list.count >= 1
		do
			name := parts_list.name
			external_id_type := parts_list.external_id_type
			inspect external_id_type when 0 then
				share (parts_list.last)
			else
				area := Empty_area
			end
		end

	make_sized (n: INTEGER)
			-- Allocate space for at least `n' characters.
		local
			s: XT_STRING_8_ROUTINES
		do
			Precursor (n)
			name := s.Empty_string
		end

feature -- Access

	external_id_type: INTEGER

	name: STRING

feature -- Status query

	is_external: BOOLEAN
		-- `True' if the entity is defined externally to document
		do
			Result := external_id_type > 0
		end

feature {NONE} -- Constants

	Empty_area: SPECIAL [CHARACTER]
		once
			create Result.make_filled ('%U', 1)
		end

end
