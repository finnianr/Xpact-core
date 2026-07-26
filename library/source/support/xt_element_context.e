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

inherit
	EL_MEMORY_ROUTINES

create
	make

feature {NONE} -- Initialization

	make (a_section_ptr: POINTER)
		local
			s: XT_STRING_ROUTINES
		do
			section_ptr := a_section_ptr
			name := s.Empty_string
		end

feature -- Access

	depth: INTEGER

	name: STRING

feature -- Status query

	has_attributes: BOOLEAN
		do
			Result := False
		end

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
			inspect depth when 1 then
				if is_attached (section_ptr) then
					c_set_byte (section_ptr, {XT_PARSE_CONSTANTS}.Prolog, True)
				end
			else end
			depth := depth - 1
		ensure
			depth_decreased: depth = old depth - 1
		end

feature {NONE} -- Internal attributes

	section_ptr: POINTER

invariant
	section_ptr_attached: is_attached (section_ptr)
end
