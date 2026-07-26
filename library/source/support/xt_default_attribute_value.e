note
	description: "Default value for an element attribute defined in the document prolog"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-26 07:10:00 GMT (Sunday 26th July 2026)"
	revision: "1"

class
	XT_DEFAULT_ATTRIBUTE_VALUE

create
	make
	
feature {NONE} -- Initialization

	make (a_name, a_value: STRING)
		do
			name := a_name; value := a_value
		end

feature -- Access

	name: STRING

	value: STRING

end
