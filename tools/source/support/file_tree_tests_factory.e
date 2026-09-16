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

	new_tests (parse_data: XT_PARSER_DATA; file_path: PATH; keep_logs: BOOLEAN): FILE_TREE_TESTS
		local
			package: XT_XML_PACKAGE
		do
			create package.make_with_path (file_path)
			if package.exists and then package.is_valid then
				create {FILE_PACKAGE_TESTS} Result.make (parse_data, package)
			else
				create Result.make (parse_data, file_path)
			end
			if keep_logs then
				Result.keep_logs
			end
		end

end
