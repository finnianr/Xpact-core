note
	description: "XML document string constants"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-11 13:14:40 GMT (Saturday 11th July 2026)"
	revision: "1"

class
	XT_STRING_CONSTANTS

feature {NONE} -- CDATA constant

	CDATA: STRING = "CDATA"

	Cdata_lsqb: C_STRING_8
		once
			Result := CDATA + "["
		end

	Attlist: INTEGER = 1

	Doctype: INTEGER = 2

	Element: INTEGER = 3

	Entity: INTEGER = 4

	Document_definition_names: LIST [STRING]
		once
			Result := ("ATTLIST,DOCTYPE,ELEMENT,ENTITY").split (',')
		ensure
			valid_first: Result [Attlist] ~ "ATTLIST"
			valid_last: Result [Entity] ~ "ENTITY"
		end

feature {NONE} -- Predefined entities

	Predefined_apos: STRING_8 = "apos"

	Predefined_amp: STRING_8 = "amp"

	Predefined_gt: STRING_8 = "gt"

	Predefined_lt: STRING_8 = "lt"

	Predefined_quot: STRING_8 = "quot"

end
