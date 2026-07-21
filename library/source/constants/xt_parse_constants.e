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

	State_initialized: INTEGER = 0
	State_parsing:     INTEGER = 1
	State_finished:    INTEGER = 2
	State_suspended:   INTEGER = 3

feature -- Parse status (XML_Status enum)

	Status_error: INTEGER = 0
	Status_ok: INTEGER = 1
	Status_suspended: INTEGER = 2
	Status_unreadable: INTEGER = 4
	Status_invalid_document: INTEGER = 5

	Status_names: STRING = "[
		Error
		OK
		Suspended
		Unreadable
		Invalid document
	]"

end
