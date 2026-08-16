note
	description: "Shared instance of ${ARRAYED_STACK [INTEGER]}."

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-05 13:40:00 GMT (Thursday 5th August 2026)"
	revision: "1"

class
	XT_SHARED_INDEX_STACK

feature {NONE} -- Constants

	Shared_index_stack: ARRAYED_STACK [INTEGER]
		once
			create Result.make (10)
		end

end
