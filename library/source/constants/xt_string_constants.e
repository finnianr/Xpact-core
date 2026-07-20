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

	Cdata_lsqb: C_STRING_8
		once
			Result := "CDATA["
		end

	Entity: C_STRING_8
		once
			Result := "ENTITY"
		end

	Empty_c_string: C_STRING_8
		once
			create Result.make_empty
		end

	Doctype: C_STRING_8
		once
			Result := "DOCTYPE"
		end

feature {NONE} -- Predefined entities

	Predefined_entities: ARRAY [C_STRING_8]
		once
			Result := << Predefined_amp, Predefined_lt, Predefined_gt, Predefined_apos, Predefined_quot >>
		ensure
			same_count: Result.count = Predefined_entity_characters.count
		end

	Predefined_entity_characters: STRING = "&<>'%""

	Predefined_apos: C_STRING_8
		once
			Result := "apos"
		end

	Predefined_amp: C_STRING_8
		once
			Result := "amp"
		end

	Predefined_gt: C_STRING_8
		once
			Result := "gt"
		end

	Predefined_lt: C_STRING_8
		once
			Result := "lt"
		end

	Predefined_quot: C_STRING_8
		once
			Result := "quot"
		end

end
