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
	make_from_i_th

feature {NONE} -- Initialization

	make_from_i_th (list: LIST [STRING]; i: INTEGER)
		require
			valid_name_index: list.valid_index (i)
			valid_value_index: list.valid_index (i + 1)
		do
			name := list [i]; value := list [i + 1]
		end

feature -- Access

	name: STRING

	value: STRING

feature -- Status query

	checked: BOOLEAN

feature -- Status query	

	check_
		do
			checked := True
		end

	uncheck
		do
			checked := False
		end
end
