note
	description: "${STRING_8} related routines"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-06-28 6:31:14 GMT (Sunday 28th June 2026)"
	revision: "1"

class
	XT_STRING_8_ROUTINES_I

inherit
	XT_SHARED_INDEX_STACK

	STRING_HANDLER

feature {NONE} -- Access

	ascii_to_utf_16 (str: STRING): STRING
		local
			i: INTEGER
		do
			create Result.make_filled ('%U', str.count * 2)
			from i := 1 until i > str.count loop
				Result [(i - 1) * 2 + 1] := str [i]
				i := i + 1
			end
		ensure then
			valid_last: Result [Result.count - 1] = str [str.count]
		end

	frozen char_ref_number (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
		-- Parse &#N; or &#xH; starting at '&'
		-- Unicode code point of the character reference starting at start_index ('&').
		-- Returns -1 if the value is not a legal XML character.
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

	frozen new_attribute_value (area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER; has_newline_or_tab: BOOLEAN): STRING_8
		-- `lower .. upper' substring of `area' placed in `output_area'
		require
			valid_upper: area.valid_index (upper)
		do
			if has_newline_or_tab then
				Result := area_substring (area, lower, upper, True)
				normalize_whitespace (Result.area, 0, Result.count - 1)
			else
				Result := area_substring (area, lower, upper, True)
			end
		end

	frozen new_abnormal_string (area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER): XT_ABNORMAL_STRING
		-- `lower .. upper' substring of `area' placed in `output_area'
		require
			valid_upper: area.valid_index (upper)
		do
			create Result.make (upper - lower + 1)
			append_area (Result, area, lower, upper)
		end

	frozen new_substring (area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER): STRING_8
		-- `lower .. upper' substring of `area' placed in `output_area'
		do
			Result := area_substring (area, lower, upper, True)
		end

	frozen new_unicode_substring (area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER): STRING_32
		-- `lower .. upper' substring of `area' placed in `output_area'
		local
			u: UTF_CONVERTER
		do
			Result := u.utf_8_string_8_to_string_32 (area_substring (area, lower, upper, False))
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
			null_terminated: Result.area [Result.count] = '%U'
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

	frozen substitute (template: STRING; insertions: ARRAY [STRING]): STRING
		require
			enough_place_holders: template.occurrences ('%S') = insertions.count
		local
			index, last_index: INTEGER; index_stack: like Shared_index_stack
		do
			Result := template.twin
			index_stack := Shared_index_stack

			last_index := template.last_index_of ('%S', template.count)
			from until index = last_index loop
				index := Result.index_of ('%S', index + 1)
				if index > 0 then
					index_stack.put (index)
				end
			end
			from until index_stack.is_empty loop
				Result.replace_substring (insertions [index_stack.count], index_stack.item, index_stack.item)
				index_stack.remove
			end
		ensure
			empty_stack: Shared_index_stack.is_empty
		end

	frozen to_list (str: STRING; c: CHARACTER): LIST [STRING]
		do
			Result := str.split (c)
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

	frozen is_ascii (area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER): BOOLEAN
		-- `True' if all characters in `area' from `lower' to `upper' are ASCII
		require
			valid_range: upper + 1 >= lower and then upper >= lower implies area.valid_index (lower) and area.valid_index (upper)
		local
			i: INTEGER
		do
			Result := True
			from i := lower until i > upper loop
				if area [i] < '%/128/' then
					i := i + 1
				else
					Result := False
					i := upper + 1 -- break
				end
			end
		end

	frozen is_ascii_string (s: STRING): BOOLEAN
		do
			Result := is_ascii (s.area, 0, s.count - 1)
		end

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
			i, j: INTEGER
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
			definition: Result implies new_substring (area, lower, upper).same_string (string)
		end

	frozen starts_with (area: SPECIAL [CHARACTER_8]; start_index: INTEGER; latin_1: STRING): BOOLEAN
		-- `True' if characters in `area' from `start_index' match those in `latin_1'
		local
			i, j, i_final, byte_count: INTEGER
		do
			byte_count := latin_1.count
			if area.valid_index (start_index + byte_count - 1) and then attached latin_1.area as string_area then
				Result := True
				i_final := start_index + byte_count - 1
				from i := start_index until i > i_final loop
					if area [i] = string_area [j] then
						i := i + 1
						j := j + 1
					else
						Result := False
						i := i_final + 1 -- break
					end
				end
			end
		end

	frozen same_caseless_characters (area: SPECIAL [CHARACTER_8]; lower, upper: INTEGER; string: STRING): BOOLEAN
		-- `True' if characters in `area' from `lower' to `upper' match those in `string' regardless of case
		local
			i, j: INTEGER; c_i, c_j: CHARACTER
		do
			if upper - lower + 1 = string.count and then attached string.area as string_area then
				Result := True
				from i := lower until i > upper loop
					c_i := area [i]; c_j := string_area [j]
					if c_i = c_j or else c_i.as_lower =  c_j.as_lower then
						i := i + 1
						j := j + 1
					else
						Result := False
						i := upper + 1 -- break
					end
				end
			end
		ensure
			definition: Result implies new_substring (area, lower, upper).same_caseless_characters (string, 1, string.count, 1)
		end

feature {NONE} -- Measurement

	frozen index_of (area: SPECIAL [CHARACTER_8]; c: CHARACTER_8; start_index, end_index: INTEGER): INTEGER
		-- Position of first occurrence of `c' at or after `start_index';
		-- -1 if none.
		require
			valid_range: start_index <= end_index + 1
			valid_start_index: area.valid_index (start_index)
			valid_end_index: end_index >= start_index implies area.valid_index (end_index)
		local
			i: INTEGER
		do
			from i := start_index until i > end_index or else area [i] = c loop
				i := i + 1
			end
			if i > end_index then
				Result := -1
			else
				Result := i
			end
		end

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

	frozen match_count (area: SPECIAL [CHARACTER_8]; offset: INTEGER; string: STRING): INTEGER
		-- count of characters in `area' from `offset' matching those from start of `string'
		require
			inside_area: area.valid_index (offset + string.count - 1)
		local
			i, string_count: INTEGER; string_area: SPECIAL [CHARACTER_8]
		do
			string_area := string.area; string_count := string_area.count
			from i := 0; until i = string_count loop
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
			count, new_count: INTEGER
		do
			count := upper - lower + 1; new_count := str.count + count
			str.grow (new_count)
			str.area.copy_data (area, lower, str.count, count)
			str.area [new_count] := '%U'
			str.set_count (new_count)
		end

	frozen fill_tuple (tuple: TUPLE; comma_separated_list: STRING)
		require
			enough_strings: tuple.count <= comma_separated_list.occurrences (',') + 1
		do
			if attached to_list (comma_separated_list, ',') as list then
				from list.start until list.after or list.index > tuple.count loop
					if tuple.valid_type_for_index (list.item, list.index) then
						tuple.put_reference (list.item, list.index)
					end
					list.forth
				end
			end
		end

	normalize_whitespace (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER)
		--  %T and %N are replaced with a space
		-- XML §3.3.3 attribute-value normalisation: replace %N %T with space
		require
			valid_range: start_index <= end_index + 1
			valid_end_index: buf.valid_index (end_index)
		local
			i: INTEGER
		do
			from i := start_index until i > end_index loop
				inspect buf [i]
					when '%T', '%N' then
						buf [i] := ' '
				else
				end
				i := i + 1
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

	Tab_spaces: STRING_8
		-- used to accumulate text for output
		once
			create Result.make_filled (' ', 3)
		end

invariant
	empty_definition: Empty_string.is_empty
end
