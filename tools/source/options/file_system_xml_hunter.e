note
	description: "Hunt file system for XML to test"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-05 07:00:00 GMT (Wednesday 5th August 2026)"
	revision: "1"

class
	FILE_SYSTEM_XML_HUNTER

inherit
	XT_FILE_HANDLER

	XT_FILE_ROUTINES_I
		rename
			extension as wild_card_extension
		end

	XT_SHARED_EXECUTION_ENVIRONMENT

create
	make

feature {NONE} -- Initialization

	make (dir_path: PATH; a_resume_at_count: INTEGER)
		local
			log_path: PATH
		do
			resume_at_count := a_resume_at_count

			if is_windows_device (dir_path) then
				create {XT_WINDOWS_DIRECTORY_WALKER} directory.make_root_with_path (dir_path)
			else
				create directory.make_with_path (dir_path)
			end
			create extension_list.make (0)
			extension_list.append (new_xml_extensions.split (';'))
			create occurrence_table.make (extension_list.count)
			create archive_occurrence_table.make (Internal_extension_table.count)
			create log_path.make_from_string ("system_xml_hunter.log")
			log_path := Environment.temporary_command_path + log_path
			Environment.make_directory (log_path.parent, False)
			create log.make_with_path (log_path)
		ensure
			valid_extensions: across extension_list as item all item.count > 0 end
		end

feature -- Basic operations

	execute
		do
			create counter
			IO.put_new_line
			occurrence_table.wipe_out; archive_occurrence_table.wipe_out
			fail_count := 0

			log.open_write
			directory.traverse (Current)

			IO.put_new_line; IO.put_new_line
			across << archive_occurrence_table, occurrence_table >> as table loop
				IO.put_string (Occurrence_headings [@ table.cursor_index])
				IO.put_integer (table.sum_occurrence_count)
				IO.put_new_line
				IO.put_string ("Extensions sorted in order of occurrence count (Highest first)")
				IO.put_new_line; IO.put_new_line
				across table.sorted_occurrence_list (False) as tag_count loop
					tag_count.io_print
				end
				IO.put_new_line
			end
			if fail_count = 0 then
				IO.put_string ("Zero failures")
				log.delete; log.close
			else
				IO.put_string ("Total failures: ")
				IO.put_integer (fail_count)
				log.close
			end
			IO.put_new_line
		end

feature {NONE} -- Implementation

	do_with (file_path: PATH)
		do
			counter := counter + 1
			if not testing_package then
				IO.put_character ('%R')
				IO.put_string (once "Files: ")
				IO.put_integer (counter)
			end
			if resume_at_count.to_boolean implies counter >= resume_at_count then
				if counter = 21856 then
					IO.put_new_line
					IO.put_string (file_path.utf_8_name)
					IO.put_new_line
				end
				do_with_resumed (file_path)
			end
		end

	do_with_resumed (file_path: PATH)
		local
			found: BOOLEAN; extension: STRING; s: XT_STRING_8_ROUTINES
			package_tests: FILE_PACKAGE_TESTS; comparison: XT_EXPAT_COMPARISON
		do
			extension := s.Empty_string
			across extension_list as item until found loop
				if file_path.has_extension (item) then -- case insensitive comparison
					extension := item; found := True
				end
			end
			if found then
				if testing_package then
					occurrence_table.put (extension) -- record internal XML extension

				elseif is_zip_archive (file_path) then
					IO.put_new_line
					IO.put_string ("Package: ")
					IO.put_string (file_path.utf_8_name)
					IO.put_new_line
					archive_occurrence_table.put (extension)
					create package_tests.make (file_path)
					package_tests.set_file_handler (Current)

					testing_package := True
					package_tests.execute -- Recursive call of `do_with'
					testing_package := False

					fail_count := fail_count + package_tests.sum_fail_count
				else
					create comparison.make (file_path, log)
					comparison.execute
					if not comparison.both_agree then
						fail_count := fail_count + 1
					end
					occurrence_table.put (extension)
				end
			end
		end

	is_windows_device (dir_path: PATH): BOOLEAN
		local
			name_parts: LIST [STRING]
		do
			name_parts := dir_path.name.to_string_8.split ('/')
			name_parts.compare_objects
			if name_parts.count > 3 then
				Result := Mount_names.has (name_parts [2]) and then name_parts.has ("Windows")
			end
		end

	Mount_names: ARRAY [STRING]
		once
			Result := << "media", "mnt" >>
			Result.compare_objects
		end

	new_xml_extensions: STRING
		do
			Result := "3mf;adml;admx;apk;appx;appxbundle;atom;axaml;config;csproj;dae;docm;docx;dotm;dotx;eant;ecf;%
				%epub;fb2;fodg;fodp;fods;fodt;fsproj;glade;gml;gpx;html;iml;ivy;kml;kmz;manifest;mathml;mml;msix;%
				%msixbundle;mum;ncx;nuspec;odb;odc;odf;odg;odi;odm;odp;ods;odt;opf;opml;otg;otp;ots;ott;owl;plist;%
				%pom;potm;potx;ppsm;ppsx;pptm;pptx;props;pubxml;rdf;resw;resx;rng;rss;ruleset;saml;sitemap;sln;soap;svg;%
				%svgz;targets;tld;tmx;ts;vbproj;vcxproj;vsixmanifest;wadl;wsdl;wsp;wxi;wxs;x3d;xacml;xaml;xamlx;%
				%xbrl;xht;xhtml;xlam;xlf;xliff;xlsm;xlsx;xltm;xltx;xml;xsd;xsl;xslt;xsp;xul"
		end

feature {NONE} -- Internal attributes

	resume_at_count: INTEGER

	fail_count: INTEGER

	extension_list: ARRAYED_LIST [STRING]

	counter: INTEGER

	archive_occurrence_table: XT_NAME_OCCURRENCE_COUNT_TABLE

	occurrence_table: XT_NAME_OCCURRENCE_COUNT_TABLE

	directory: XT_DIRECTORY_WALKER

	log: PLAIN_TEXT_FILE

	testing_package: BOOLEAN

feature {NONE} -- Constants

	Occurrence_headings: ARRAY [STRING]
		once
			Result := << "Total zipped archive packages: ", "Total XML files: " >>
		end

end
