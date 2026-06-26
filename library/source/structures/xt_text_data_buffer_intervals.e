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

feature -- Status report

	set_is_c_data
		do
			is_cdata := True
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
