note
	description: "[
		Concrete implementations of the name-checking predicates for
		UTF-16 Little-Endian encoding, using the Unicode naming bitmaps
		from XT_NAME_BITMAP.

		Corresponds to LITTLE2_IS_NAME_CHAR_MINBPC / LITTLE2_IS_NMSTRT_CHAR_MINBPC
		in xmltok.c, implemented via the UCS2_GET_NAMING formula:

		    namingBitmap [(pages [hi] |<< 3) + (lo |>> 5)] & (1 |<< (lo & 0x1F))

		where hi = buf [ptr + 1]  (high byte, second in LE order) and
		      lo = buf [ptr]      (low byte,  first  in LE order).

		The _2 predicates check a single 2-byte UTF-16 code unit covering the
		BMP range U+0080..U+FFFD, excluding surrogates and the noncharacters
		U+FFFE / U+FFFF.  The _3 predicates always return False because UTF-16
		has no 3-byte code units.  The _4 predicates address surrogate pairs,
		which encode supplementary characters U+10000..U+10FFFF; these are valid
		XML characters but are never name or name-start characters in XML 1.0.

		Diamond join note: this class and the scanner mixins both inherit
		XT_SCANNER_HELPERS.  Eiffel's join rule resolves the shared deferred
		features automatically -- no rename or redefine needed here.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-28 12:00:00 GMT (Tuesday 28th July 2026)"
	revision: "1"

class XT_UTF_16_NAME_CHECKER

inherit
	XT_NAME_BITMAP

feature -- Name-character predicates (2-byte UTF-16 LE code unit, U+0080..U+FFFD)

	is_name_char_2 (buf: SPECIAL [CHARACTER]; ptr: INTEGER): BOOLEAN
			-- Is the 2-byte UTF-16 LE code unit at ptr a valid XML NameChar?
			-- Uses name_pages and the naming bitmap (UCS2_GET_NAMING).
		local
			hi, lo, pg, idx: INTEGER
		do
			lo := buf [ptr].code
			hi := buf [ptr + 1].code
			pg := name_pages [hi].to_integer_32
			idx := (pg |<< 3) + (lo |>> 5)
			Result := (naming_bitmap [idx] & ({NATURAL_32} 1 |<< (lo & 0x1F))) /= 0
		end

	is_name_start_char_2 (buf: SPECIAL [CHARACTER]; ptr: INTEGER): BOOLEAN
			-- Is the 2-byte UTF-16 LE code unit at ptr a valid XML NameStartChar?
			-- Uses name_start_pages and the naming bitmap.
		local
			hi, lo, pg, idx: INTEGER
		do
			lo := buf [ptr].code
			hi := buf [ptr + 1].code
			pg := name_start_pages [hi].to_integer_32
			idx := (pg |<< 3) + (lo |>> 5)
			Result := (naming_bitmap [idx] & ({NATURAL_32} 1 |<< (lo & 0x1F))) /= 0
		end

	is_invalid_char_2 (buf: SPECIAL [CHARACTER]; ptr: INTEGER): BOOLEAN
			-- True for the noncharacters U+FFFE (0xFE 0xFF in LE) and
			-- U+FFFF (0xFF 0xFF in LE).
		do
			Result := buf [ptr + 1].code = 0xFF
				and (buf [ptr].code = 0xFE or buf [ptr].code = 0xFF)
		end

feature -- Name-character predicates (3-byte sequences -- not applicable in UTF-16)

	is_name_char_3 (buf: SPECIAL [CHARACTER]; ptr: INTEGER): BOOLEAN
			-- UTF-16 has no 3-byte code units; always False.
		do
			Result := False
		end

	is_name_start_char_3 (buf: SPECIAL [CHARACTER]; ptr: INTEGER): BOOLEAN
		do
			Result := False
		end

	is_invalid_char_3 (buf: SPECIAL [CHARACTER]; ptr: INTEGER): BOOLEAN
		do
			Result := False
		end

feature -- Name-character predicates (4-byte surrogate pairs, U+10000..U+10FFFF)

	is_name_char_4 (buf: SPECIAL [CHARACTER]; ptr: INTEGER): BOOLEAN
			-- Supplementary characters (U+10000 and above) are not NameChars in XML 1.0.
		do
			Result := False
		end

	is_name_start_char_4 (buf: SPECIAL [CHARACTER]; ptr: INTEGER): BOOLEAN
			-- Supplementary characters are not NameStartChars in XML 1.0.
		do
			Result := False
		end

	is_invalid_char_4 (buf: SPECIAL [CHARACTER]; ptr: INTEGER): BOOLEAN
			-- A UTF-16 LE surrogate pair is invalid if its second code unit
			-- (bytes at ptr + 2 and ptr + 3) is not a low surrogate.
			-- The high byte of the second unit is at ptr + 3; it must be in
			-- 0xDC..0xDF for a well-formed low surrogate.
		do
			Result := (buf [ptr + 3].code & 0xFC) /= 0xDC
		end

end
