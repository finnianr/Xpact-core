note
	description: "List of indices demarking text data substrings in ${XT_XML_PARSER}.buffer"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-22 18:20:41 GMT (Monday 22th June 2026)"
	revision: "1"
class
	XT_TEXT_DATA_BUFFER_INTERVALS

inherit
	XT_CHARACTER_BUFFER_INTERVALS
		redefine
			wipe_out
		end

create
	make

feature -- Status report

	is_cdata: BOOLEAN

feature -- Status setting

	set_is_c_data
		do
			is_cdata := True
		end

feature -- Access

	adjusted_concatenation (buffer: SPECIAL [CHARACTER_8]): STRING_8
		-- concatenated `text_intervals' substrings found in `buffer'
		-- Trims leading and trailing white space and first and last intervals
		do
			Result := output_buffer
			Result.wipe_out
			append_to (buffer, Result)
			Result.right_adjust
		ensure
			is_text_buffer: Result = output_buffer
		end

feature -- Basic operations

	append_to (a_buffer: SPECIAL [CHARACTER_8]; str: STRING)
		-- append all substring intervals in `buffer' to `str'
		local
			i, j, upper_index: INTEGER; c_i: CHARACTER; first_copied: BOOLEAN
			buffer: SPECIAL [CHARACTER_8]
		do
			buffer := a_buffer
			str.grow (character_count)
			if attached str.area as area_out and then attached overflow_buffer_area as overflow then
				from j := 0 start until after loop
					if attached item_interval as array then
						if attached overflow [(index - 1) // 2] as overflow_buffer then
							buffer := overflow_buffer
						else
							buffer := a_buffer
						end
						upper_index := array [1]
						from i := array [0] until i > upper_index loop
							c_i := buffer [i]
							if not first_copied then
								first_copied := not c_i.is_space
							end
							if first_copied then
								area_out [j] := c_i
								j := j + 1
							end
							i := i + 1
						end
					end
					forth
				end
				str.set_count (j)
			end
		end

	wipe_out
		do
			Precursor; is_cdata := False
		end

feature {NONE} -- Implementation

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (n)
		end

feature {NONE} -- Constants

	Group_size: INTEGER = 2
end
