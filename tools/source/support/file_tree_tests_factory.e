note
	description: "Creates an instance of ${FILE_TREE_TESTS}"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-03 17:00:00 GMT (Monday 3rd August 2026)"
	revision: "1"

class
	FILE_TREE_TESTS_FACTORY

inherit
	XT_FILE_ROUTINES_I

feature {NONE} -- Implementation

	new_tests (file_path: PATH; keep_logs: BOOLEAN): FILE_TREE_TESTS
		do
			if is_xml_package (file_path) then
				create {FILE_PACKAGE_TESTS} Result.make (file_path)
			else
				create Result.make (file_path)
			end
			if keep_logs then
				Result.keep_logs
			end
		end

end
