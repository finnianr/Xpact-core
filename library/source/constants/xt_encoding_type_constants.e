note
	description: "Encoding type identifiers"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-25 19:39:38 GMT (Thursday 25th June 2026)"
	revision: "1"

class
	XT_ENCODING_TYPE_CONSTANTS

inherit
	CODE_PAGE_CONSTANTS
		rename
			 Utf8 as Utf_8_name,
			 utf16 as Utf_16_name
		export
			{NONE} all
		end

feature {NONE} -- Constants

	Ascii: NATURAL_8 = 1

	Latin_1: NATURAL_8 = 2

	Utf_8: NATURAL_8 = 3

	Utf_16: NATURAL_8 = 4

	Encoding_names_upper: ARRAY [STRING]
		once
			Result := << "US-ASCII", "ISO-8859-1", Utf_8_name, Utf_16_name >>
		end

	Encoding_attribute: STRING = "encoding"

	Valid_encoding_list: STRING = "UTF-8, UTF-16, UTF-16BE, UTF-16LE, ISO-8859-1, US-ASCII"

end
