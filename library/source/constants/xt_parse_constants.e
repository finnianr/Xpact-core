note
	description: "Constants ported from expat.h and xmlparse.c (libexpat 2.x)"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 8:37:26 GMT (Saturday 20th June 2026)"
	revision: "1"

class XT_PARSE_CONSTANTS

feature {NONE} -- Parsing states (XML_Parsing enum)

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

feature {NONE} -- Parse status (XML_Status enum)

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

feature {XT_STRING_CONSTANTS} -- Declaration types

	Valid_declaration_types: INTEGER_INTERVAL
		once
			Result := Attlist |..| Notation
		end

	Attlist: INTEGER = 1

	Doctype: INTEGER = 2

	Element: INTEGER = 3

	Entity: INTEGER = 4

	Notation: INTEGER = 5

	Parameter_entity: INTEGER = 6

feature {NONE} -- Content expansion

	Default_runway_expansion_threshold: NATURAL_64 = 0x800000
		-- number of bytes processed after which checks for
		-- runaway expansion should be performed

	Default_max_expansion_proportion: DOUBLE = 100.0

	Source_content: NATURAL_8 = 0

	Source_expansion: NATURAL_8 = 1
		-- entity expansion

	Source_expansion_with_checks: NATURAL_8 = 2
		-- entity expansion and instruction to test if `max_expansion_proportion' exceeded

end
