note
	description: "C routines from C header `<string.h>'"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-06-29 6:31:14 GMT (Monday 29th June 2026)"
	revision: "1"

class
	EL_STRING_H_C_API

inherit
	EL_C_API

feature {NONE} -- C Externals

	frozen c_strcmp_n (p1: POINTER; n1: INTEGER; p2: POINTER; n2: INTEGER): INTEGER
			-- Lexicographic comparison of `n1' bytes at `p1' with `n2' bytes at `p2'.
			-- Returns negative if p1 < p2, zero if equal, positive if p1 > p2.
		external
			"C inline use <string.h>"
		alias
			"[
				int n = ($n1 < $n2) ? $n1 : $n2;
				int cmp = memcmp($p1, $p2, n);
				if (cmp != 0) return cmp;
				return ($n1 < $n2) ? -1 : ($n1 > $n2) ? 1 : 0;
			]"
		end

	frozen c_string_8_length (a_area: POINTER): INTEGER
			-- length of null terminated string at `a_area'.
		external
			"C inline"
		alias
			"return (EIF_INTEGER_32)strlen ((const char *)$a_area);"
		end

	frozen c_memory_compare (p1, p2: POINTER; n: INTEGER): BOOLEAN
		-- True if first `n' bytes at `p1' and `p2' are identical.
		external
			"C inline use <string.h>"
		alias
			"return (memcmp ($p1, $p2, $n) == 0);"
		end

	frozen c_read_character_8 (a_area: POINTER; i: INTEGER): CHARACTER_8
			-- Character at offset `i' in buffer `a_area'.
		external
			"C inline"
		alias
			"return ((EIF_CHARACTER_8 *)$a_area)[$i];"
		end

	frozen c_read_natural_16 (a_area: POINTER; i: INTEGER): NATURAL_16
			-- 16 bit unsigned integer at offset `i' in buffer `a_area'.
		external
			"C inline"
		alias
			"return ((EIF_NATURAL_16 *)$a_area)[$i];"
		end

	frozen c_utf_16_to_ascii (src: POINTER; unit_count: INTEGER; dest: POINTER): INTEGER
			-- convert leading run of ASCII code units in UTF-16 buffer `src' to single bytes in `dest',
			-- stopping at the first unit >= 0x80 or after `unit_count' units.
			-- Returns count of units converted.
			-- Note: the 64-bit mask test assumes a little-endian host (x86, x64, ARM64 Linux/Windows).
		external
			"C inline use <string.h>"
		alias
			"[
				const EIF_NATURAL_16 *u = (const EIF_NATURAL_16 *) $src;
				EIF_CHARACTER_8 *out = (EIF_CHARACTER_8 *) $dest;
				EIF_INTEGER_32 i = 0, n = $unit_count;
				while (i + 4 <= n) {
					EIF_NATURAL_64 four;
					memcpy (&four, u + i, 8);
					if (four & 0xFF80FF80FF80FF80ULL) break;
					out [i] = (EIF_CHARACTER_8) u [i];
					out [i + 1] = (EIF_CHARACTER_8) u [i + 1];
					out [i + 2] = (EIF_CHARACTER_8) u [i + 2];
					out [i + 3] = (EIF_CHARACTER_8) u [i + 3];
					i += 4;
				}
				while (i < n && u [i] < 0x80) {
					out [i] = (EIF_CHARACTER_8) u [i];
					i += 1;
				}
				return i;
			]"
		end

	frozen c_read_natural_64 (a_area: POINTER; i: INTEGER): NATURAL_64
			-- 64 bit unsigned integer at byte offset `i' in buffer `a_area'.
		external
			"C inline use <string.h>"
		alias
			"[
				EIF_NATURAL_64 result;
				memcpy (&result, (const char *) $a_area + $i, 8);
				return result;
			]"
		end
end
