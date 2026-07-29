note
	description: "[
		Attribute buffer intervals for XML documents encoded in UTF-16
		Little-Endian.

		The shared parse buffer holds raw UTF-16 LE bytes: each code unit
		occupies two consecutive bytes, the low byte first.  The three
		conversion features implement the abstract contract from
		XT_ATTRIBUTE_BUFFER_INTERVALS:

		  utf_8_bytes_count -- bytes needed to re-encode the interval as UTF-8
		  to_utf_8          -- transcode UTF-16 LE bytes -> UTF-8 bytes
		  to_utf_16         -- copy UTF-16 LE byte pairs -> NATURAL_16 words

		Surrogate pairs (U+10000..U+10FFFF) are handled in all three features:
		`utf_8_bytes_count' charges 4 UTF-8 bytes per pair, `to_utf_8' emits a
		full 4-byte UTF-8 sequence by decoding the pair, and `to_utf_16' copies
		both code units (4 bytes) as two consecutive NATURAL_16 words.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-28 12:00:00 GMT (Tuesday 28th July 2026)"
	revision: "1"

class
	XT_UTF_16_ATTRIBUTE_INTERVALS

inherit
	XT_ATTRIBUTE_BUFFER_INTERVALS
		undefine
			advance, area_count, char_width, copy_characters, latin_1_count, offset_by
		redefine
			new_name_cache, not_utf_8_encoded, new_entity_cache, new_entity_table
		end

	XT_STRING_16_ROUTINES_I
		undefine
			copy, is_equal
		end

create
	make

feature -- Measurement

	utf_8_bytes_count (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
			-- Number of UTF-8 bytes needed to represent the UTF-16 LE data in
			-- buf [start_index .. end_index].
		local
			i, hi, lo, cp: INTEGER
		do
			from i := start_index until i + 1 > end_index loop
				lo := buf [i].code
				hi := buf [i + 1].code
				cp := (hi |<< 8) | lo
				if cp < 0x80 then
					Result := Result + 1
				elseif cp < 0x800 then
					Result := Result + 2
				elseif cp >= 0xD800 and cp <= 0xDBFF then
					-- high surrogate: surrogate pair encodes U+10000..U+10FFFF -> 4 UTF-8 bytes
					Result := Result + 4
					i := i + 2  -- skip the low-surrogate code unit
				else
					Result := Result + 3
				end
				i := i + 2
			end
		end

feature {NONE} -- Factory

	new_entity_cache: XT_UTF_16_ENTITY_NAME_CACHE
		do
			create Result.make
		end

	new_entity_table (n: INTEGER): XT_UTF_16_ENTITY_TABLE
		do
			create Result.make (n)
		end

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (n)
		end

	new_name_cache: XT_UTF_16_NAME_CACHE
		do
			create Result.make
		end

feature {NONE} -- Implementation

	to_utf_8 (source, dest: SPECIAL [CHARACTER]; start_index, end_index: INTEGER)
			-- Transcode UTF-16 LE bytes source [start_index .. end_index] to UTF-8
			-- in dest.  Surrogate pairs are decoded into a 4-byte UTF-8 sequence.
		local
			i, hi, lo, cp, high_s, low_s: INTEGER
		do
			from i := start_index until i + 1 > end_index or dest.count = dest.capacity loop
				lo := source [i].code
				hi := source [i + 1].code
				cp := (hi |<< 8) | lo
				if cp < 0x80 then
					dest.extend (cp.to_character_8)

				elseif cp < 0x800 then
					if dest.count + 2 <= dest.capacity then
						dest.extend ((0xC0 | (cp |>> 6)).to_character_8)
						dest.extend ((0x80 | (cp & 0x3F)).to_character_8)
					end

				elseif cp >= 0xD800 and cp <= 0xDBFF and i + 3 <= end_index then
					-- decode surrogate pair -> code point -> 4-byte UTF-8
					high_s := cp
					lo := source [i + 2].code
					hi := source [i + 3].code
					low_s := (hi |<< 8) | lo
					cp := 0x10000 + ((high_s - 0xD800) |<< 10) + (low_s - 0xDC00)
					if dest.count + 4 <= dest.capacity then
						dest.extend ((0xF0 | (cp |>> 18)).to_character_8)
						dest.extend ((0x80 | ((cp |>> 12) & 0x3F)).to_character_8)
						dest.extend ((0x80 | ((cp |>> 6) & 0x3F)).to_character_8)
						dest.extend ((0x80 | (cp & 0x3F)).to_character_8)
						i := i + 2  -- extra advance past the low-surrogate code unit
					end

				else
					if dest.count + 3 <= dest.capacity then
						dest.extend ((0xE0 | (cp |>> 12)).to_character_8)
						dest.extend ((0x80 | ((cp |>> 6) & 0x3F)).to_character_8)
						dest.extend ((0x80 | (cp & 0x3F)).to_character_8)
					end
				end
				i := i + 2
			end
		end

	to_utf_16 (source: SPECIAL [CHARACTER]; dest: SPECIAL [NATURAL_16]; start_index, end_index: INTEGER)
			-- Copy UTF-16 LE byte pairs from source [start_index .. end_index] into
			-- dest as NATURAL_16 words (little-endian reassembly).
			-- Surrogate pairs are copied as two consecutive NATURAL_16 values.
		local
			i: INTEGER
		do
			from i := start_index until i + 1 > end_index or dest.count = dest.capacity loop
				dest.extend ((source [i].code | (source [i + 1].code |<< 8)).to_natural_16)
				i := i + 2
			end
		end

	not_utf_8_encoded (lower_index, upper_index, utf_8_count: INTEGER): BOOLEAN
		do
			Result := True
		end
end
