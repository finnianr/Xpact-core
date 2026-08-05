note
	description: "Shared instance of ${XT_EXECUTION_ENVIRONMENT}"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-02 07:32:00 GMT (Sunday 2th August 2026)"
	revision: "1"

class
	XT_SHARED_EXECUTION_ENVIRONMENT

feature {NONE} -- Constants

	Environment: XT_EXECUTION_ENVIRONMENT
		once
			create Result
		end

end
