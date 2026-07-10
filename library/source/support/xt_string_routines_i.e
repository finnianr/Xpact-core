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

	Output_buffer: STRING_8
		-- used to accumulate text for output
		once
			create Result.make (20)
		end

end
