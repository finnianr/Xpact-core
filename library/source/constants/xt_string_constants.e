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

feature {NONE} -- Declaration qualifiers

	CDATA: STRING = "CDATA"

	NDATA: STRING = "NDATA"

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

	Xml_declaration: TUPLE [open, encoding, standalone, version: STRING]
		local
			s: XT_STRING_8_ROUTINES
		once
			create Result
			s.fill_tuple (Result, "<?xml, encoding, standalone, version")
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

feature {NONE} -- Constants

	BT_names_list: LIST [STRING]
		once
			Result := ("[
				Non xml
				Malform
				Less than
				Ampersand
				Right square bracket
				Lead 2 byte
				Lead 3 byte
				Lead 4 byte
				Continuation byte
				CR
				Linefeed
				Greater than
				Quote
				Apostrophe
				Equals
				Question
				Exclamation
				Forward slash
				Semicolon
				Hash
				Left square bracket
				Whitespace
				Name start
				Colon
				Hex digit
				Digit
				Name only
				Minus
				Other
				Non ascii
				Percent
				Left parenthesis
				Right parenthesis
				Asterisk
				Plus
				Comma
				Pipe symbol
			]").split ('%N')
		ensure
			valid_start_index: Result [{XT_BYTE_TYPE_CONSTANTS}.Bt_non_xml + 1] ~ "Non xml"
			valid_end_index: Result [{XT_BYTE_TYPE_CONSTANTS}.BT_pipe_symbol + 1] ~ "Pipe symbol"
		end

end
