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

create
	make

feature {NONE} -- Initialization

	make (dir_path: PATH)
		do
			create directory.make_with_path (dir_path)
			create extension_list.make (0)
			extension_list.append (new_xml_extensions.split (';'))
			across extension_list as extension loop
				extension.grow (extension.count + 1)
				extension.prepend_character ('.')
			end
			create occurrence_table.make (extension_list.count)
		end

feature -- Basic operations

	execute
		do
			create counter
			IO.put_new_line
			directory.traverse (Current)
			IO.put_new_line; IO.put_new_line
			IO.put_string ("Total XML files: ")
			IO.put_integer (occurrence_table.sum_occurrence_count)
			IO.put_new_line
			IO.put_string ("Extensions sorted in order of occurrence count (Highest first)")
			IO.put_new_line; IO.put_new_line
			across occurrence_table.sorted_occurrence_list (False) as tag_count loop
				tag_count.io_print ("EXTENSION")
			end
		end

feature {NONE} -- Implementation

	do_with (file_path: PATH)
		local
			found: BOOLEAN
		do
			counter := counter + 1
			IO.put_character ('%R')
			IO.put_string (once "Files: ")
			IO.put_integer (counter)
			if attached file_path.utf_8_name as name then
				across extension_list as extension until found loop
					if name.ends_with (extension) then
						found := True
						occurrence_table.put (extension)
					end
				end
			end
		end

	new_xml_extensions: STRING
		do
			Result := "3mf;adml;admx;apk;appx;appxbundle;atom;axaml;config;csproj;dae;docm;docx;dotm;dotx;eant;ecf;%
				%epub;fb2;fodg;fodp;fods;fodt;fsproj;glade;gml;gpx;iml;ivy;jar;kml;kmz;manifest;mathml;mml;msix;%
				%msixbundle;mum;ncx;nuspec;odb;odc;odf;odg;odi;odm;odp;ods;odt;opf;opml;otg;otp;ots;ott;owl;plist;%
				%pom;potm;potx;ppsm;ppsx;pptm;pptx;props;pubxml;rdf;resw;resx;rng;rss;ruleset;saml;sitemap;sln;svg;%
				%svgz;targets;tld;tmx;ts;vbproj;vcxproj;vsixmanifest;wadl;wsdl;wsp;wxi;wxs;x3d;xacml;xaml;xamlx;%
				%xbrl;xht;xhtml;xlam;xlf;xliff;xlsm;xlsx;xltm;xltx;xml;xsd;xsl;xslt;xsp;xul"
		end

feature {NONE} -- Internal attributes

	extension_list: ARRAYED_LIST [STRING]

	counter: INTEGER

	occurrence_table: XT_NAME_OCCURRENCE_COUNT_TABLE

	directory: XT_DIRECTORY_WALKER

end
