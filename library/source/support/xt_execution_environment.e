note
	description: "Extended ${EXECUTION_ENVIRONMENT}."

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-18 09:40:00 GMT (Saturday 18th July 2026)"
	revision: "1"

class
	XT_EXECUTION_ENVIRONMENT

inherit
	EXECUTION_ENVIRONMENT

feature -- Access

	temporary_path (name: STRING): PATH
		do
			if attached Temporary_directory_path as dir_path and then attached dir_path.extended (name) as path then
				Result := path
			else
				create Result.make_empty
			end
		end
end
