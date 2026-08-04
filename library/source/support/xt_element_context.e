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
		do
			section_flags := a_section_flags
			create empty_attribute_values.make_empty (0)
			create stack.make_empty (50)
		end

feature -- Access

	depth: INTEGER
		do
			Result := stack.count
		end

	name: STRING
		local
			s: like stack
		do
			s := stack
			Result := s [s.count - 1]
		end

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
		local
			s: like stack
		do
			s := stack
			if s.count + 1 > stack.capacity then
				s := s.aliased_resized_area ((stack.capacity * 1.3).ceiling)
				stack := s
			end
			s.extend (a_name)
		ensure
			depth_increased: depth = old depth + 1
		end

	pop (a_name: STRING): INTEGER
		require
			is_nested: depth > 0
		local
			s: like stack
		do
			s := stack
			if a_name /= s [s.count - 1] then
				Result := {XT_PARSE_ERROR_CONSTANTS}.Error_tag_mismatch
			end
			s.remove_tail (1)
			inspect depth when 0 then
				section_flags [{XT_PARSE_CONSTANTS}.Prolog] := True
				reached_depth_zero := true
			else end
		ensure
			depth_decreased: depth = old depth - 1
		end

	reset
		do
			reached_depth_zero := False
		end

feature {NONE} -- Internal attributes

	empty_attribute_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE]

	section_flags: SPECIAL [BOOLEAN]

	stack: SPECIAL [STRING]

end
