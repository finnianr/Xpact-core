note
	description: "Context of current element node being handled"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-25 18:10:00 GMT (Saturday 25th July 2026)"
	revision: "1"

class
	XT_ELEMENT_CONTEXT

create
	make

feature {NONE} -- Initialization

	make (a_section_flags: SPECIAL [BOOLEAN])
		local
			s: XT_STRING_ROUTINES
		do
			section_flags := a_section_flags
			name := s.Empty_string
			create empty_attribute_values.make_empty (0)
		end

feature -- Access

	depth: INTEGER

	name: STRING

	default_attribute_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE]
		do
			Result := empty_attribute_values
		ensure
			all_attributes_unchecked: across Result as value all not value.checked end
		end

feature -- Status query

	has_attributes: BOOLEAN
		do
			Result := False
		end

	reached_depth_zero: BOOLEAN

feature -- Element change

	push (a_name: STRING)
		do
			depth := depth + 1
			name := a_name
		ensure
			depth_increased: depth = old depth + 1
		end

	pop
		require
			is_nested: depth > 0
		do
			depth := depth - 1
			inspect depth when 0 then
				section_flags [{XT_PARSE_CONSTANTS}.Prolog] := True
				reached_depth_zero := true
			else end
		ensure
			depth_decreased: depth = old depth - 1
		end

feature {NONE} -- Internal attributes

	empty_attribute_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE]

	section_flags: SPECIAL [BOOLEAN]

end
