note
	description: "Count of occurrences of a tag"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-08-05 12:39:00 GMT (Wednesday 5th August 2026)"
	revision: "2"

class
	XT_NAME_OCCURRENCE_COUNT

inherit
	COMPARABLE

create
	make

feature {NONE} -- Initialisation

	make (a_name: STRING)
		do
			name := a_name
		end

feature -- Access

	count: INTEGER

	name: STRING

feature -- Basic operations

	increment
		do
			count := count + 1
		end

	io_print
		do
			io.put_character ('<')
			io.put_string (name)
			io.put_string (">: occurrences ")
			io.put_integer (count)
			io.put_new_line
		end

feature -- Comparison

	is_less alias "<" (other: like Current): BOOLEAN
			-- Is `other' greater than current character?
		do
			Result := count < other.count
		end
end
