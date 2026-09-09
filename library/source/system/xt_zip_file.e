note
	description: "Zip archive file"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-09 08:14:00 GMT (Wednesday 9th September 2026)"
	revision: "1"

class
	XT_ZIP_FILE

inherit
	RAW_FILE

	XT_SHARED_EXECUTION_ENVIRONMENT

create
	make_with_path

feature -- Status query

	is_extracted: BOOLEAN

	is_valid: BOOLEAN
		-- `True' if `path'is a valid zip archive that can be extracted
		-- ZIP files start with one of these byte sequences:

		-- PK\x03\x04 normal file entry (most common start)
		-- PK\x05\x06 empty archive (End of Central Directory only)
		-- PK\x07\x08 spanned/split archive
		local
			i: INTEGER
		do
			read_header
			if Header.count = Header_size and then Header.starts_with_string (PK_string, 0) then
				from i := 3 until i > 8 or Result loop
					if Header [3] = i.to_character_8 and then Header [4] = (i + 1).to_character_8 then
						Result := True
					else
						i := i + 2
					end
				end
			end
		end

feature -- Basic operations

	extract (destination_path: PATH)
		require
			valid_zip_archive: is_valid
		local
			s: XT_STRING_8_ROUTINES
		do
			Environment.make_directory (destination_path, False)
			Environment.do_command (Unzip_template, s.new_string_list (<< path, destination_path >>))
			is_extracted := Environment.return_code = 0
		end

feature {NONE} -- Implementation

	read_header
		-- Read archive header into `Header'
		local
			file: RAW_FILE
		do
			open_read
			if file_readable and count > Header_size then
				Header.read_file (Current, Header_size)
			end
			close
		end

feature {NONE} -- Constants

	Header: EL_MANAGED_C_STRING_8
		once
			create Result.make (Header_size)
		end

	PK_string: STRING = "PK"

	Header_size: INTEGER = 4

	Unzip_template: STRING
		once
			Result := "unzip -q %S -d %S"
		end

end
