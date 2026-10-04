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

feature -- Contract support

	valid_encoding (a_encoding: INTEGER): BOOLEAN
		do
			Result := Encoding_names_upper.valid_index (a_encoding)
		end

feature {NONE} -- Encoding types

	ASCII: INTEGER = 1

	Latin_1: INTEGER = 2

	UTF_8: INTEGER = 3

	UTF_16_BE: INTEGER = 4

	UTF_16_LE: INTEGER = 5

	UTF_16: INTEGER = 6

	Unknown_encoding: INTEGER = 0

feature {NONE} -- Constants

	Encoding_byte_order_marks: ARRAY [STRING]
		require
			valid_order: UTF_8 < UTF_16_LE and UTF_16_BE < UTF_16_LE
		local
			uc: UTF_CONVERTER
		once
			create Result.make_filled (uc.utf_8_bom_to_string_8, UTF_8, UTF_16_LE)
			Result [UTF_16_BE] := uc.utf_16be_bom_to_string_8
			Result [UTF_16_LE] := uc.utf_16le_bom_to_string_8
		end

	Encoding_names_upper: LIST [STRING]
		local
			s: XT_STRING_8_ROUTINES
		once
			Result := s.to_list (Valid_encoding_list, ',')
			Result.compare_objects
		ensure
			first_is_ascii: Result [Ascii] ~ "US-ASCII"
			last_is_Utf_16_le: Result [Utf_16] ~ "UTF-16"
		end

	Valid_encoding_list: STRING = "US-ASCII, ISO-8859-1, UTF-8, UTF-16BE, UTF-16LE, UTF-16"

end
