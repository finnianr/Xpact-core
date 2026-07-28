note
	description: "[
		Concrete UTF-16 Little-Endian document scanner.

		Each XML character occupies exactly two bytes in the parse buffer stored
		with the low byte first (Little-Endian order).  char_width = 2, so
		`advance (index)' moves by 2 bytes and all character-count arithmetic
		naturally works in code units.

		Byte-type dispatch:
		  The scanner mixin code uses `bt_table [buf [index].code]', which reads
		  only the LOW byte at each index.  For ASCII characters (high byte = 0x00)
		  the low byte IS the ASCII value, so the classification is correct.  For
		  BMP characters whose high byte is non-zero the low-byte table entry is
		  not semantically meaningful; as a safe fallback all bytes 0x80..0xFF are
		  mapped to BT_non_ascii (= 29), causing the scanner to advance by
		  char_width = 2 and treat them as ordinary data characters.

		  The `byte_type (buf, index)' feature below performs the correct two-byte
		  lookup for a UTF-16 LE code unit and is the intended override point.
		  Once XT_SCANNER_HELPERS is extended with a virtual `byte_type' and the
		  scanner mixin code is updated to call it instead of `bt_table [...]',
		  non-ASCII element names, attribute names, and surrogate pairs will be
		  classified correctly.

		Known limitations with the current single-byte dispatch:
		  * Element / attribute names containing non-ASCII BMP characters
		    (high byte /= 0x00) will not be recognised as names.
		  * Surrogate pairs (U+10000+) whose low byte falls in the range
		    0x00..0x7F are misclassified by the ASCII portion of the table.
		  * `predefined_entity_code' uses byte-count arithmetic from the parent;
		    it must be redefined when entity reference handling for UTF-16 is needed.

		These issues only affect files with non-ASCII markup identifiers or
		supplementary-plane characters; purely ASCII XML structure is handled
		correctly.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-28 12:00:00 GMT (Tuesday 28th July 2026)"
	revision: "1"

class XT_UTF_16_SCANNER

inherit
	XT_DOCUMENT_SCANNER
		rename
			area_count as character_count
		undefine
			character_count, copy_characters, latin_1_count,
			is_name_char_2, is_name_char_3, is_name_char_4,
			is_name_start_char_2, is_name_start_char_3, is_name_start_char_4,
			is_invalid_char_2, is_invalid_char_3, is_invalid_char_4
		redefine
			offset_by
		end

	XT_UTF_16_NAME_CHECKER

	XT_STRING_16_ROUTINES_I
		rename
			area_count as character_count
		end

create
	make

feature -- Encoding identity

	is_utf_8: BOOLEAN = False

	is_utf_16: BOOLEAN = True

feature -- Byte-type dispatch

	byte_type (buf: SPECIAL [CHARACTER]; index: INTEGER): INTEGER
			-- Two-byte byte type for the UTF-16 LE code unit at `index'.
			-- When the high byte (buf [index + 1]) is zero the character is
			-- ASCII and its type is read from byte_type_table.  Otherwise
			-- `unicode_byte_type' classifies it as BT_non_ascii, BT_lead_4_byte
			-- (high surrogate 0xD8..0xDB), BT_continuation_byte (low surrogate
			-- 0xDC..0xDF) or BT_non_xml (U+FFFE / U+FFFF).
			--
			-- This feature is the intended override point for the scanner mixin
			-- code once XT_SCANNER_HELPERS exposes a virtual `byte_type'.
		local
			hi: INTEGER
		do
			hi := buf [index + 1].code
			if hi = 0 then
				Result := byte_type_table [buf [index].code]
			else
				Result := unicode_byte_type (hi, buf [index].code)
			end
		end

feature -- Byte-type table

	byte_type_table: SPECIAL [INTEGER]
			-- 256-entry fallback table: ASCII half (0x00..0x7F) filled with
			-- standard BT_* values via `fill_ascii_half'; bytes 0x80..0xFF
			-- mapped to BT_non_ascii so the scanner advances by char_width = 2
			-- for every non-ASCII code unit without triggering an error.
		once
			create Result.make_filled (0, 256)
			fill_ascii_half (Result)
			Result.fill_with (BT_non_ascii, 128, 255)
		end

feature -- Character-count and offset scaling (redefined for char_width = 2)

	offset_by (index, offset: INTEGER): INTEGER
			-- Byte index `offset' characters after `index' (index + offset * 2).
			-- Overrides the default `index + offset' in XT_SCANNER_HELPERS.
		do
			Result := index + offset * 2
		end

feature {NONE} -- Factory

	new_attribute_intervals: XT_UTF_16_ATTRIBUTE_INTERVALS
		do
			create Result.make (11)
		end

feature {NONE} -- Unicode code-unit classification (port of xmltok.c unicode_byte_type)

	unicode_byte_type (hi, lo: INTEGER): INTEGER
			-- Classify a non-ASCII UTF-16 code unit by its high byte `hi' and
			-- low byte `lo'.  Mirrors the static `unicode_byte_type (char, char)'
			-- in xmltok.c.
		do
			inspect hi
				when 0xD8, 0xD9, 0xDA, 0xDB then
					Result := BT_lead_4_byte       -- high surrogate (U+D800..U+DBFF)
				when 0xDC, 0xDD, 0xDE, 0xDF then
					Result := BT_continuation_byte -- low surrogate  (U+DC00..U+DFFF)
				when 0xFF then
					if lo = 0xFF or lo = 0xFE then
						Result := BT_non_xml       -- U+FFFF / U+FFFE
					else
						Result := BT_non_ascii
					end
			else
				Result := BT_non_ascii
			end
		end

end
