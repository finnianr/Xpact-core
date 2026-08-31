note
	description: "[
		${STRING_8} with attribute `is_open' for XML entity name to detect if an internal entity
		refers back to itself, either directly or through a chain.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-21 11:02:00 GMT (Friday 21th August 2026)"
	revision: "1"

class
	XT_ENTITY_NAME

inherit
	STRING

create
	make, make_empty, make_from_buffer, make_shared

feature {NONE} -- Initialization

	make_from_buffer (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; delimiter: CHARACTER)
		-- take buffer segment from `start_index' to `end_index' and insert into "&;" at position 2
		local
			l_count, full_count: INTEGER
		do
			l_count := end_index - start_index + 1
			full_count := l_count + 2
			make_filled ('%U', full_count)

			if attached area as a then
				a [0] := delimiter -- '&' OR '%'
				a.copy_data (buffer, start_index, 1, l_count)
				a [full_count - 1] := ';'
			end
			is_dtd_expandable := delimiter = '%%' or buffer [start_index] = '#'
		end

	make_shared (s: STRING)
		do
			area := s.area; count := s.count
			internal_hash_code := 0
			internal_case_insensitive_hash_code := 0
		end

feature -- Status query

	is_open: BOOLEAN

	is_dtd_expandable: BOOLEAN
		-- `True' if entity should be expanded in literal values referenced in document type definition

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
