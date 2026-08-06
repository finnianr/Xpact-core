note
	description: "${XT_FILE_HANDLER} that does nothing"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-09-05 07:55:00 GMT (Thursday 5th August 2026)"
	revision: "1"

class
	XT_DO_NOTHING_FILE_HANDLER

inherit
	XT_FILE_HANDLER

feature -- Basic operations

	do_with (file_path: PATH)
		do
		end
end
