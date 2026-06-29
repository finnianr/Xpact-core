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

feature -- Access

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

	frozen buffer_substring (buffer: SPECIAL [CHARACTER_8]; lower, upper: INTEGER; keep_ref: BOOLEAN): STRING_8
		-- `lower .. upper' substring of `buffer' placed in `output_buffer'
		require
			valid_range: upper + 1 >= lower and then upper >= lower implies buffer.valid_index (lower) and buffer.valid_index (upper)
		local
			count, i: INTEGER
		do
			Result := output_buffer
			Result.wipe_out
			count := upper - lower + 1
			Result.grow (count)
			if attached Result.area as area_out then
				from i := 0 until i = count loop
					area_out [i] := buffer [i + lower]
					i := i + 1
				end
				Result.set_count (i)
			end
			if keep_ref then
				Result := Result.twin
			end
		ensure
			not_keeping_definition: not keep_ref implies Result = output_buffer
		end

feature {NONE} -- Constants

	output_buffer: STRING_8
		-- used to accumulate text for output
		once
			create Result.make (20)
		end

end
