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

feature {NONE} -- Standard strings

	CDATA: STRING = "CDATA"

	Cdata_lsqb: STRING
		once
			Result := CDATA + "["
		end

	Document_definition_names: LIST [STRING]
		once
			Result := ("ATTLIST,DOCTYPE,ELEMENT,ENTITY,NOTATION").split (',')
			Result.compare_objects
		ensure
			valid_first: Result [{XT_PARSE_CONSTANTS}.Attlist] ~ "ATTLIST"
			valid_last: Result [{XT_PARSE_CONSTANTS}.Notation] ~ "NOTATION"
		end

	Http: STRING = "http"

	PUBLIC: STRING = "PUBLIC"

	SYSTEM: STRING = "SYSTEM"

	Xml_lower: STRING = "xml"

	Xml_declaration: STRING = "<?xml"

	Comment_declaration: STRING = "<!--"

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
			aligned_with_bt_value: Result [{XT_BYTE_TYPE_CONSTANTS}.BT_pipe_symbol + 1] ~ "Pipe symbol"
		end

end
