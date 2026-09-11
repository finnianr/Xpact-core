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

feature {NONE} -- Reserved names

	ANY: STRING = "ANY"

	CDATA: STRING = "CDATA"

	EMPTY: STRING = "EMPTY"

	ENTITY: STRING = "ENTITY"

	ENTITIES: STRING = "ENTITIES"

	ID: STRING = "ID"

	IDREF: STRING = "IDREF"

	IDREFS: STRING = "IDREFS"

	NDATA: STRING = "NDATA"

	NMTOKEN: STRING = "NMTOKEN"

	NMTOKENS: STRING = "NMTOKENS"

	NOTATION: STRING = "NOTATION"

	PUBLIC: STRING = "PUBLIC"

	SYSTEM: STRING = "SYSTEM"

feature {NONE} -- Standard strings

	Cdata_lsqb: STRING
		once
			Result := CDATA + "["
		end

	Comment_declaration: STRING = "<!--"

	Quote_marks: STRING = "'%""

	Xml_lower: STRING = "xml"

	Xml_declaration: TUPLE [open, version, encoding, standalone: STRING]
		local
			s: XT_STRING_8_ROUTINES
		once
			create Result
			s.fill_tuple (Result, "<?xml, version, encoding, standalone")
		end

feature {NONE} -- Document definition strings

	Document_definition_names: LIST [STRING]
		local
			s: XT_STRING_8_ROUTINES
		once
			Result := s.to_list ("ATTLIST, DOCTYPE, ELEMENT, ENTITY, NOTATION", ',')
			Result.compare_objects
		ensure
			valid_first: Result [{XT_PARSE_CONSTANTS}.Attlist] ~ "ATTLIST"
			valid_last: Result [{XT_PARSE_CONSTANTS}.Notation] ~ "NOTATION"
		end

	Common_starts_with: LIST [STRING]
		-- common leading strings at start of document after initial white space
		local
			s: XT_STRING_8_ROUTINES
		once
			Result := s.to_list ("<?xml, <!DOC, <!--", ',')
		end

	Http: STRING = "http"

	Unknown_id: STRING = "Unknown"

	Valid_external_id_list: ARRAY [STRING]
		once
			Result := << PUBLIC, SYSTEM >>
		end

feature {NONE} -- XML declaration

	Valid_yes_no: ARRAY [STRING]
		once
			Result := << "yes", "no" >>
			Result.compare_objects
		end

feature {NONE} -- Predefined entities

	Predefined_apos: STRING_8 = "apos"

	Predefined_amp: STRING_8 = "amp"

	Predefined_gt: STRING_8 = "gt"

	Predefined_lt: STRING_8 = "lt"

	Predefined_quot: STRING_8 = "quot"

end
