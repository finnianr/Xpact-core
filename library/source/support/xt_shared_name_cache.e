note
	description: "An empty name cache to satisfy void-safe compilation"
	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-06-28 6:31:14 GMT (Sunday 28th June 2026)"
	revision: "1"

class
	XT_SHARED_NAME_CACHE

feature {NONE} -- Constants

	Empty_name_cache: XT_NAME_CACHE
		once ("PROCESS")
			create Result.make_empty
		end
end
