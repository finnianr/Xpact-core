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

feature {NONE} -- Constants

	Ascii: NATURAL_8 = 1

	Latin_1: NATURAL_8 = 2

	Utf_8: NATURAL_8 = 3

	Utf_16: NATURAL_8 = 4

	Unknown_encoding: NATURAL_8 = 0

	Encoding_names_upper: LIST [STRING]
		local
			s: XT_STRING_8_ROUTINES
		once
			Result := s.to_list ("US-ASCII, ISO-8859-1, UTF-8, UTF-16", ',')
		end

	Valid_encoding_list: STRING = "UTF-8, UTF-16, UTF-16BE, UTF-16LE, ISO-8859-1, US-ASCII"

end
