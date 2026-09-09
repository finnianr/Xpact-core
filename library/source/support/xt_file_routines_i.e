note
	description: "File related routines"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-05 16:50:00 GMT (Wednesday 5th August 2026)"
	revision: "1"
class
	XT_FILE_ROUTINES_I

inherit
	XT_XML_PACKAGE_CONSTANTS

feature {NONE} -- Implementation

	extension (wild_card: STRING): STRING
		local
			index: INTEGER; s: XT_STRING_8_ROUTINES
		do
			index := wild_card.index_of ('.', 1)
			if index > 0 then
				Result := wild_card.substring (index + 1, wild_card.count)
			else
				Result := s.Empty_string
			end
		ensure
			not_empty: Result.count > 0
		end

	internal_wild_cards (wild_card: STRING): LIST [STRING]
		do
			if attached Internal_extension_table [extension (wild_card)] as list then
				Result := list.split (';')
			else
				Result := Default_internal_wild_cards
			end
		end

	new_find_results (dir_path: PATH; wild_card: STRING): XT_COMMAND_OUTPUT_FILE
		do
			create Result.make_with_output (Find_file_template, << dir_path, wild_card >>)
		-- Check if find command tried to access directories requiring root permission
		-- find: '/etc/cups/ssl': Permission denied
			if Result.has_errors and then
				across Result.error_lines as line all
					line.ends_with (": Permission denied")
				end
			then
			-- all permission errors so fine to read results
				Result.open_read
			end
		end

feature {NONE} -- Constants

	Find_file_template: STRING
		once
			Result := "[
				find # -type f -name "#"
			]"
		end

end
