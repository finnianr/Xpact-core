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
			create directory.make_with_path (dir_path)
			create extension_list.make (0)
			extension_list.append (new_xml_extensions.split (';'))
			create occurrence_table.make (extension_list.count)
			create log_path.make_from_string ("system_xml_hunter.log")
			log_path := Environment.temporary_command_path + log_path
			Environment.make_directory (log_path.parent, False)
			create log.make_with_path (log_path)
		end

feature -- Basic operations

	execute
		do
			create counter
			IO.put_new_line

			log.open_write
			directory.traverse (Current)
			if log.count = 0 then
				log.delete; log.close
			end

			IO.put_new_line; IO.put_new_line
			IO.put_string ("Total XML files: ")
			IO.put_integer (occurrence_table.sum_occurrence_count)
			IO.put_new_line
			IO.put_string ("Extensions sorted in order of occurrence count (Highest first)")
			IO.put_new_line; IO.put_new_line
			across occurrence_table.sorted_occurrence_list (False) as tag_count loop
				tag_count.io_print ("EXTENSION")
			end
			if fail_count = 0 then
				IO.put_string ("Total failures: ")
				IO.put_integer (fail_count)
			else
				IO.put_string ("Zero failures")
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
				do_with_resumed (file_path)
			end
		end

	do_with_resumed (file_path: PATH)
		local
			found: BOOLEAN; extension: STRING; s: XT_STRING_8_ROUTINES
			package_tests: FILE_PACKAGE_TESTS; comparison: XT_EXPAT_COMPARISON
		do
			extension := s.Empty_string
			across extension_list as l_extension until found loop
				if file_path.has_extension (l_extension) then -- case insensitive comparison
					found := True
					extension := l_extension
				end
			end
			if testing_package then
				occurrence_table.put (extension) -- record internal XML extension

			elseif found then
				if is_zip_archive (file_path) then
					IO.put_new_line
					testing_package := True
					IO.put_string ("Package: ")
					IO.put_string (file_path.utf_8_name)
					IO.put_new_line
					create package_tests.make (file_path)
					package_tests.set_file_handler (Current)
					package_tests.execute
					fail_count := fail_count + package_tests.sum_fail_count
					testing_package := False
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

	new_xml_extensions: STRING
		do
			Result := "3mf;adml;admx;apk;appx;appxbundle;atom;axaml;config;csproj;dae;docm;docx;dotm;dotx;eant;ecf;%
				%epub;fb2;fodg;fodp;fods;fodt;fsproj;glade;gml;gpx;iml;ivy;jar;kml;kmz;manifest;mathml;mml;msix;%
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

	occurrence_table: XT_NAME_OCCURRENCE_COUNT_TABLE

	directory: XT_DIRECTORY_WALKER

	log: PLAIN_TEXT_FILE

	testing_package: BOOLEAN

end
