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

	is_zip_archive (file_path: PATH): BOOLEAN
		-- ZIP files start with one of these byte sequences:

		-- PK\x03\x04 normal file entry (most common start)
		-- PK\x05\x06 empty archive (End of Central Directory only)
		-- PK\x07\x08 spanned/split archive
		local
			i: INTEGER
		do
			if read_file_header (file_path) = 4 and then File_header.starts_with (PK_string) then
				from i := 3 until i > 8 or Result loop
					if File_header [3] = i.to_character_8 and then File_header [4] = (i + 1).to_character_8 then
						Result := True
					else
						i := i + 2
					end
				end
			end
		end

	is_xml_package (file_path: PATH): BOOLEAN
		do
			if attached file_path.entry as entry then
				Result := Internal_extension_table.has (extension (entry.utf_8_name))
			end
		end

	new_find_results (dir_path: PATH; wild_card: STRING): XT_COMMAND_OUTPUT_FILE
		do
			create Result.make_with_output (Find_template, << dir_path, wild_card >>)
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

	read_file_header (file_path: PATH): INTEGER
		-- Read file header into `File_header'
		local
			file: RAW_FILE
		do
			create file.make_with_path (file_path)
			file.open_read
			if file.file_readable and file.count > 4 then
				file.read_to_managed_pointer (File_header, 0, File_header.count)
				Result := file.bytes_read
			end
			file.close
		end

feature {NONE} -- Constants

	File_header: EL_MANAGED_C_STRING_8
		once
			create Result.make (4)
		end

	Find_template: STRING
		once
			Result := "[
				find # -type f -name "#"
			]"
		end

feature {NONE} -- Constants

	Default_internal_wild_cards: ARRAYED_LIST [STRING]
		once
			create Result.make_from_array (<< Dot_xml >>)
		end

	Dot_xml: STRING = "*.xml"

	Dot_xml_rels: STRING = "*.xml;*.rels"

	Internal_extension_table: HASH_TABLE [STRING, STRING]
		once
			create Result.make_from_iterable_tuples (<<
			-- OOXML: Word
				[Dot_xml_rels,			"docx"],
				[Dot_xml_rels,			"docm"],
				[Dot_xml_rels,			"dotx"],
				[Dot_xml_rels,			"dotm"],
			-- OOXML: Excel
				[Dot_xml_rels,			"xlsx"],
				[Dot_xml_rels,			"xlsm"],
				[Dot_xml_rels,			"xltx"],
				[Dot_xml_rels,			"xltm"],
				[Dot_xml_rels,			"xlam"],
			-- OOXML: PowerPoint
				[Dot_xml_rels,			"pptx"],
				[Dot_xml_rels,			"pptm"],
				[Dot_xml_rels,			"potx"],
				[Dot_xml_rels,			"potm"],
				[Dot_xml_rels,			"ppsx"],
				[Dot_xml_rels,			"ppsm"],
			-- ODF: text, spreadsheet, presentation, drawing
				[Dot_xml,				"odt"],
				[Dot_xml,				"ott"],
				[Dot_xml,				"ods"],
				[Dot_xml,				"ots"],
				[Dot_xml,				"odp"],
				[Dot_xml,				"otp"],
				[Dot_xml,				"odg"],
				[Dot_xml,				"otg"],
			-- ODF: formula, database, chart, image, master
				[Dot_xml,				"odf"],
				[Dot_xml,				"odb"],
				[Dot_xml,				"odc"],
				[Dot_xml,				"odi"],
				[Dot_xml,				"odm"],
			-- Zipped KML
				["*.kml",				"kmz"],
			-- Windows app packages
				[Dot_xml,				"appx"],
				[Dot_xml,				"appxbundle"],
				[Dot_xml,				"msix"],
				[Dot_xml,				"msixbundle"],
			-- EPUB
				["*.opf;*.ncx;*.xhtml;*.xml",	"epub"],
			-- 3D Manufacturing Format
				["*.model;*.rels;*.xml", "3mf"]
			>>)
		end

	PK_string: EL_CHARACTER_8_BUFFER
		once
			create Result.make_from_string ("PK")
		end

end
