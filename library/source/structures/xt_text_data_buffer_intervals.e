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

create
	make

feature {NONE} -- Implementation

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (n)
		end

feature {NONE} -- Constants

	Group_size: INTEGER = 2
end
