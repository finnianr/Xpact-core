note
	description: "${STRING_8} routines"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-06-28 6:31:14 GMT (Sunday 28th June 2026)"
	revision: "1"

class
	XT_STRING_ROUTINES_I

inherit
	STRING_HANDLER

feature {NONE} -- Access

	frozen char_ref_number (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
			-- Parse &#N; or &#xH; starting at '&'.  Returns the code point or -1.
		local
			index: INTEGER; is_hex: BOOLEAN; c: CHARACTER
		do
			index := start_index + 2  -- skip '&' and '#'
			if index < end_index and buf [index] = 'x' then
				is_hex := True; index := index + 1
			end
			from until index >= end_index or buf [index] = ';' loop
				c := buf [index]
				if is_hex then
					inspect c
						when '0'..'9' then
							Result := (Result |<< 4) | (c - 48).code
						when 'A'..'F' then
							Result := (Result |<< 4) | (c - 55).code
					else
					-- 'a'..'f'
						Result := (Result |<< 4) | (c - 87).code
					end
				else
					Result := Result * 10 + (c - 48).code
				end
				if Result >= 0x110000 then
					Result := -1; index := end_index
				else
					index := index + 1
				end
			end
		end

	frozen new_substring (area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER): STRING_8
		-- `lower .. upper' substring of `area' placed in `output_area'
		do
			Result := area_substring (area, lower, upper, True)
		end

	frozen area_substring (area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER; keep_ref: BOOLEAN): STRING_8
		-- `lower .. upper' substring of `area' placed in `output_area'
		do
			Result := Output_buffer
			Result.wipe_out
			append_area (Result, area, lower, upper)
			if keep_ref then
				Result := Result.twin
			end
		ensure
			not_keeping_definition: not keep_ref implies Result = Output_buffer
		end

	frozen key_set_string (key_list: ITERABLE [STRING]; keep_ref: BOOLEAN): STRING
		-- << "a", "b" >> -> "{a, b}"
		do
			Result := Output_buffer
			Result.wipe_out
			Result.append_character ('{')
			across key_list as key loop
				if Result.count > 2 then
					Result.append_string (", ")
				end
				Result.append_string (key)
			end
			Result.append_character ('}')
			if keep_ref then
				Result := Result.twin
			end
		end

	frozen to_list (str: STRING): LIST [STRING]
		do
			Result := str.split (',')
			Result.do_all (agent {STRING}.left_adjust)
		end

	frozen unescaped (code: INTEGER): like Char_area
		do
			Result := Char_area
			Result [0] := code.to_character_8
		end

	frozen utf_8_encoded (cp: INTEGER): like Char_area
		-- Encode Unicode code point `cp' as UTF-8 into `area'.
		-- Returns the number of bytes written (1..4).
		do
			Result := Char_area
			Result.wipe_out

			if cp <= 0x7F then
				Result.extend (cp.to_character_8)
			elseif cp <= 0x7FF then
				Result.extend ((0xC0 | (cp |>> 6)).to_character_8)
				Result.extend ((0x80 | (cp & 0x3F)).to_character_8)
			elseif cp <= 0xFFFF then
				Result.extend ((0xE0 | (cp |>> 12)).to_character_8)
				Result.extend ((0x80 | ((cp |>> 6) & 0x3F)).to_character_8)
				Result.extend ((0x80 | (cp & 0x3F)).to_character_8)
			else
				Result.extend ((0xF0 | (cp |>> 18)).to_character_8)
				Result.extend ((0x80 | ((cp |>> 12) & 0x3F)).to_character_8)
				Result.extend ((0x80 | ((cp |>> 6) & 0x3F)).to_character_8)
				Result.extend ((0x80 | (cp & 0x3F)).to_character_8)
			end
		end

	frozen valid_char_ref (code: INTEGER): INTEGER
			-- Return code if it is a legal XML character, else -1.
		do
			if code < 0 then
				Result := -1
			elseif (code |>> 8) >= 0xD8 and (code |>> 8) <= 0xDF then
				Result := -1  -- UTF-16 surrogate range
			elseif code < 0x20 and code /= 0x09 and code /= 0x0A and code /= 0x0D then
				Result := -1  -- forbidden C0 control characters
			elseif code = 0xFFFE or code = 0xFFFF then
				Result := -1  -- non-characters
			elseif code > 0x10FFFF then
				Result := -1  -- beyond Unicode range
			else
				Result := code
			end
		end

feature {NONE} -- Status report

	frozen is_white_space (area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER): BOOLEAN
		-- count of leading whitespace in `area' from `lower' to `upper'
		require
			valid_range: upper + 1 >= lower and then upper >= lower implies area.valid_index (lower) and area.valid_index (upper)
		local
			i: INTEGER
		do
			Result := True
			from i := lower until i > upper loop
				if area [i].is_space then
					i := i + 1
				else
					Result := False
					i := upper + 1 -- break
				end
			end
		end

	frozen same_characters (area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER; string: STRING): BOOLEAN
		-- `True' if characters in `area' from `lower' to `upper' match those in `string'
		local
			i, j, string_count: INTEGER
		do
			if upper - lower + 1 = string.count and then attached string.area as string_area then
				Result := True
				from i := lower until i > upper loop
					if area [i] = string_area [j] then
						i := i + 1
						j := j + 1
					else
						Result := False
						i := upper + 1 -- break
					end
				end
			end
		ensure
			definition: Result implies area [lower] = string [1] and area [upper] = string [string.count]
		end

feature {NONE} -- Measurement

	frozen leading_white_space (area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER): INTEGER
		-- count of leading whitespace in `area' from `lower' to `upper'
		require
			valid_range: upper + 1 >= lower and then upper >= lower implies area.valid_index (lower) and area.valid_index (upper)
		local
			i: INTEGER
		do
			from i := lower until i > upper loop
				if area [i].is_space then
					Result := Result + 1; i := i + 1
				else
					i := upper + 1 -- break
				end
			end
		end

	frozen match_count (area, string_area: SPECIAL [CHARACTER_8]; offset: INTEGER): INTEGER
		-- count of characters in `area' from `offset' matching those in `string_area' from 0 to `string_area.count - 2'
		require
			null_terminated: string_area [string_area.count - 1] = '%U'
			inside_area: area.valid_index (offset + string_area.count - 2)
		local
			i, string_count: INTEGER
		do
			from i := 0; string_count := string_area.count - 1 until i = string_count loop
				if area [offset + i] = string_area [i] then
					Result := Result + 1
					i := i + 1
				else
					i := string_count -- break
				end
			end
		end

feature {NONE} -- Basic operations

	frozen append_area (str: STRING_8; area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER)
		-- append contents of `area' from `lower' to `upper' to `str'
		require
			valid_range: upper + 1 >= lower and then upper >= lower implies area.valid_index (lower) and area.valid_index (upper)
		local
			count, new_count, i, j: INTEGER
		do
			count := str.count; new_count := count + upper - lower + 1
			str.grow (new_count)
			if attached str.area as area_out then
				from i := lower; j := count until i > upper loop
					area_out [j] := area [i]
					i := i + 1; j := j + 1
				end
				str.set_count (new_count)
			end
		end

	frozen substitute (template: STRING; insertions: ARRAY [STRING]): STRING
		require
			enough_place_holders: template.occurrences ('%S') = insertions.count
		local
			index: INTEGER
		do
			Result := template.twin
			across insertions as str loop
				index := Result.index_of ('%S', 1)
				if index > 0 then
					Result.replace_substring (str, index, index)
				end
			end
		end

feature {NONE} -- Constants

	Char_area: SPECIAL [CHARACTER]
		-- scratch 4-byte buffer for resolved entity/char-ref characters
		once
			create Result.make_filled ('%U', 4)
		end

	Empty_string: STRING_8
		-- used to accumulate text for output
		once
			create Result.make_empty
		end

	Output_buffer: STRING_8
		-- used to accumulate text for output
		once
			create Result.make (20)
		end

invariant
	empty_definition: Empty_string.is_empty
end
