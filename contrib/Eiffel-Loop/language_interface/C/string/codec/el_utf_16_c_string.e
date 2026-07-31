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
			character_count, make_shared, reset
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

feature -- Element change

	reset
		do
			partial_code_unit := 0
		end

feature -- Basic operations

	copy_as_utf_8 (dest: SPECIAL [CHARACTER]; dest_index, n: INTEGER)
		local
			dest_full, partial_pair: BOOLEAN; ptr: POINTER
			i, i_final, j, remaining_count, code_unit, high_16, low_16, partial_unit, ascii_count: INTEGER
		do
			partial_unit := partial_code_unit
			partial_code_unit := 0
			ptr := area; i_final := character_count - 1
			remaining_count := n
			from i := 0; j := dest_index until i > i_final or dest_full or partial_pair loop
				inspect partial_unit when 0 then
				-- bulk convert leading run of ASCII code units
					ascii_count := utf_16_to_ascii (ptr + i * 2, (i_final - i + 1).min (remaining_count), dest, j)
					i := i + ascii_count; j := j + ascii_count
					remaining_count := remaining_count - ascii_count
				else
				end
				if i > i_final then
					do_nothing -- all remaining input consumed by ASCII fast path

				else
					inspect partial_unit when 0 then
						code_unit := read_natural_16 (ptr, i)
					else
						code_unit := partial_unit -- residual unit from previous call to `copy_as_utf_8'
						i := i - 1
						partial_unit := 0
					end
					if code_unit < 0x80 then
					-- fast path stopped for lack of output space
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
								dest [j] := (0xF0 | (code_unit |>> 18)).to_character_8
								dest [j + 1] := (0x80 | ((code_unit |>> 12) & 0x3F)).to_character_8
								dest [j + 2] := (0x80 | ((code_unit |>> 6) & 0x3F)).to_character_8
								dest [j + 3] := (0x80 | (code_unit & 0x3F)).to_character_8
								j := j + 4
								remaining_count := remaining_count - 4
								i := i + 1
							end
						else
						-- lone high surrogate at end of chunk: consume it here and
						-- carry it forward in `partial_code_unit' so that `last_index'
						-- and the residual unit are not counted twice
							partial_code_unit := code_unit
							i := i + 1
							partial_pair := True
						end
					else
						inspect remaining_count when 0, 1, 2 then
							dest_full := True
						else
							dest [j] := (0xE0 | (code_unit |>> 12)).to_character_8
							dest [j + 1] := (0x80 | ((code_unit |>> 6) & 0x3F)).to_character_8
							dest [j + 2] := (0x80 | (code_unit & 0x3F)).to_character_8
							j := j + 3
							remaining_count := remaining_count - 3
							i := i + 1
						end
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

	frozen utf_16_to_ascii (src: POINTER; unit_count: INTEGER; dest: SPECIAL [CHARACTER]; dest_index: INTEGER): INTEGER
			-- convert leading run of ASCII code units in UTF-16 buffer `src' to single bytes
			-- in `dest' from `dest_index', stopping at the first unit >= 0x80 or after
			-- `unit_count' units. Returns count of units converted.
			-- Note: the 64-bit mask test assumes a little-endian host.
		local
			i, n, code_unit: INTEGER; four: NATURAL_64; broken: BOOLEAN
		do
			n := unit_count
			from until i + 4 > n or broken loop
				four := c_read_natural_64 (src, i * 2)
				if (four & Non_ascii_mask) = 0 then
					dest [dest_index + i] := c_read_natural_16 (src, i).to_character_8
					dest [dest_index + i + 1] := c_read_natural_16 (src, i + 1).to_character_8
					dest [dest_index + i + 2] := c_read_natural_16 (src, i + 2).to_character_8
					dest [dest_index + i + 3] := c_read_natural_16 (src, i + 3).to_character_8
					i := i + 4
				else
					broken := True
				end
			end
			from broken := False until i = n or broken loop
				code_unit := c_read_natural_16 (src, i)
				if code_unit < 0x80 then
					dest [dest_index + i] := code_unit.to_character_8
					i := i + 1
				else
					broken := True
				end
			end
			Result := i
		ensure
			valid_count: Result >= 0 and Result <= unit_count
		end

feature {NONE} -- Constants

	Non_ascii_mask: NATURAL_64 = 0xFF80_FF80_FF80_FF80

end
