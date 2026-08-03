note
	description: "Constants ported from expat.h and xmlparse.c (libexpat 2.x)"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 8:37:26 GMT (Saturday 20th June 2026)"
	revision: "1"

class XT_PARSE_CONSTANTS

feature -- Parsing states (XML_Parsing enum)

	Parsing_states: ARRAY [INTEGER]
		once
			Result := <<
				State_check_encoding,
				State_initialized,
				State_parsing,
				State_finished,
				State_suspended
			>>
		end

	State_check_encoding: INTEGER = 0
	State_initialized: INTEGER = 1
	State_parsing: INTEGER = 2
	State_finished: INTEGER = 3
	State_suspended: INTEGER = 4

feature -- Parse status (XML_Status enum)

	Status_error: INTEGER = 0
	Status_ok: INTEGER = 1
	Status_suspended: INTEGER = 2

	Status_range: INTEGER_INTERVAL
		once
			Result := Status_error |..| Status_suspended
		end

	Status_names: STRING = "[
		Error
		OK
		Suspended
	]"

feature -- Declaration types

	Attlist: INTEGER = 1

	Doctype: INTEGER = 2

	Element: INTEGER = 3

	Entity: INTEGER = 4

feature -- Parsing sections

	Prolog: INTEGER = 0

	CDATA: INTEGER = 1

end
