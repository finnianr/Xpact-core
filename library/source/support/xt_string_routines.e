note
	description: "Incremental XML file parser"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-26 18:21:11 GMT (Friday 26th June 2026)"
	revision: "1"

expanded class
	XT_STRING_ROUTINES

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
end
