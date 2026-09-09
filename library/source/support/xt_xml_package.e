note
	description: "Tree structure of XML files in a zipped archive"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-09 08:48:00 GMT (Wednesday 9th September 2026)"
	revision: "1"

class
	XT_XML_PACKAGE

inherit
	XT_ZIP_FILE
		redefine
			is_valid
		end

	XT_FILE_ROUTINES_I

create
	make_with_path

feature -- Status query

	is_valid: BOOLEAN
		do
			if Precursor and then attached path.entry as entry then
				Result := Internal_extension_table.has (extension (entry.utf_8_name))
			end
		end
end
