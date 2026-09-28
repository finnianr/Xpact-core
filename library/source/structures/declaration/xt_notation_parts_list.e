note
	description: "[
		Parts of NOTATION declaration in document type defintion.
		
		For examle:

			<!NOTATION gif SYSTEM "viewer.exe">
			<!NOTATION jpg PUBLIC "-//Example//NOTATION JPEG//EN">
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-09-01 14:23:00 GMT (Tuesday 1st September 2026)"
	revision: "1"

class
	XT_NOTATION_PARTS_LIST

inherit
	XT_DECLARATION_PARTS_LIST
		redefine
			new_name, is_valid
		end

create
	make

feature -- Status query

	is_valid: BOOLEAN
		do
			if count = 1 then
				if has_public_id then
					Result := external_id_list.count > 0

				elseif has_system_id then
					Result := external_id_list.count = 1
				end
			end
		end

feature {NONE} -- Factory

	new_name (buffer: SPECIAL [CHARACTER_8]; start_index, end_index: INTEGER): STRING_8
		do
			Result := new_substring (buffer, start_index, end_index)
		end

end
