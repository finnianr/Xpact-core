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

feature {NONE} -- Implementation

	new_tests (file_path: PATH; keep_logs: BOOLEAN): FILE_TREE_TESTS
		do
			if attached file_path.entry as entry and then is_xml_package (entry.name) then
				create {FILE_PACKAGE_TESTS} Result.make (file_path)
			else
				create Result.make (file_path)
			end
			if keep_logs then
				Result.keep_logs
			end
		end

	is_xml_package (wild_card: READABLE_STRING_GENERAL): BOOLEAN
		local
			s: XT_STRING_ROUTINES
		do
			across s.to_list (Compressed_files, ';') as l_wild_card until Result loop
				Result := wild_card.same_string (l_wild_card)
			end
		end

feature {NONE} -- Constants

	Compressed_files: STRING
		once
			Result := "*.ods; *.odt; *.docx"
		end

end
