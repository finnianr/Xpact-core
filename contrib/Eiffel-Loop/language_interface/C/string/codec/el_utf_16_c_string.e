note
	description: "Decode UTF-16 managed pointer to UTF-8"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-30 07:48:00 GMT (Thursday 30th July 2026)"
	revision: "1"
class
	EL_UTF_16_C_STRING

inherit
	EL_UTF_8_POINTER_CODEC
		rename
			count as byte_count,
			read_natural_16 as read_natural_16_
		redefine
			character_count, make_shared
		end

create
	make, make_shared

feature {NONE} -- Initialization

	make_shared (a_ptr: POINTER; n: INTEGER)
		-- Initialize buffer with the contents of `codec'.
		require else
			even_byte_count: n.integer_remainder (2) = 0
		do
			Precursor (a_ptr, n)
		end

feature -- Access

	partial_code_unit: INTEGER

	character_count: INTEGER
		do
			Result := byte_count // 2
		end

feature -- Basic operations

	copy_as_utf_8 (dest: SPECIAL [CHARACTER]; dest_index, n: INTEGER)
		local
			dest_full, partial_pair: BOOLEAN; ptr: POINTER
			i, i_final, j, remaining_count, code_unit, high_16, low_16, partial_unit, code_unit_count: INTEGER
		do
			partial_unit := partial_code_unit
			code_unit_count := character_count
			ptr := area; i_final := code_unit_count - 1
			remaining_count := n
			from i := 0; j := dest_index until i > i_final or dest_full or partial_pair loop
				inspect partial_unit when 0 then
					code_unit := read_natural_16 (ptr, i)
				else
					code_unit := partial_unit -- residual unit from previous call to `copy_as_utf_8'
					i := i - 1
					partial_unit := 0
				end
				if code_unit < 0x80 then
					inspect remaining_count when 0 then
						dest_full := True
					else
						dest [j] := code_unit.to_character_8
						j := j + 1
						remaining_count := remaining_count - 1
						i := i + 1
					end
				elseif code_unit < 0x800 then
					inspect remaining_count when 0, 1 then
						dest_full := True
					else
						dest [j] := (0xC0 | (code_unit |>> 6)).to_character_8
						dest [j + 1] := (0x80 | (code_unit & 0x3F)).to_character_8
						j := j + 2
						remaining_count := remaining_count - 2
						i := i + 1
					end
				elseif code_unit >= 0xD800 and code_unit <= 0xDBFF then
					-- decode surrogate pair -> code point -> 4-byte UTF-8
					if i + 1 <= i_final then
						inspect remaining_count when 0, 1, 2, 3 then
							dest_full := True
						else
							high_16 := code_unit
							i := i + 1
							low_16 := read_natural_16 (ptr, i)
							code_unit := 0x10000 + ((high_16 - 0xD800) |<< 10) + (low_16 - 0xDC00)
							dest [j + 1] := (0xF0 | (code_unit |>> 18)).to_character_8
							dest [j + 2] := (0x80 | ((code_unit |>> 12) & 0x3F)).to_character_8
							dest [j + 3] := (0x80 | ((code_unit |>> 6) & 0x3F)).to_character_8
							dest [j + 4] := (0x80 | (code_unit & 0x3F)).to_character_8
							j := j + 4
							remaining_count := remaining_count - 4
							i := i + 1
						end
					else
						partial_code_unit := code_unit
						partial_pair := True
					end
				else
					inspect remaining_count when 0, 1, 2 then
						dest_full := True
					else
						dest [j + 1] := (0xE0 | (code_unit |>> 12)).to_character_8
						dest [j + 2] := (0x80 | ((code_unit |>> 6) & 0x3F)).to_character_8
						dest [j + 3] := (0x80 | (code_unit & 0x3F)).to_character_8
						j := j + 3
						remaining_count := remaining_count - 3
						i := i + 1
					end
				end
			end
			utf_8_copied_count := n - remaining_count
			last_index := i * 2
		end

feature {NONE} -- Implementation

	frozen read_natural_16 (a_area: POINTER; i: INTEGER): NATURAL_16
		require
			valid_index: i < byte_count - 1
		do
			Result := c_read_natural_16 (a_area, i)
		end

end
