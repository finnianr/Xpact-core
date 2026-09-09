note
	description: "XML file extensions and related constants"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-09 09:16:00 GMT (Wednesday 9th September 2026)"
	revision: "1"

class
	XT_XML_PACKAGE_CONSTANTS

feature {NONE} -- Implementation

	new_xml_extensions: STRING
		do
			Result := "3mf;adml;admx;apk;appx;appxbundle;atom;axaml;config;csproj;dae;docm;docx;dotm;dotx;eant;ecf;%
				%epub;fb2;fodg;fodp;fods;fodt;fsproj;glade;gml;gpx;html;iml;ivy;kml;kmz;manifest;mathml;mml;msix;%
				%msixbundle;mum;ncx;nuspec;odb;odc;odf;odg;odi;odm;odp;ods;odt;opf;opml;otg;otp;ots;ott;owl;plist;%
				%pom;potm;potx;ppsm;ppsx;pptm;pptx;props;pubxml;rdf;resw;resx;rng;rss;ruleset;saml;sitemap;soap;svg;%
				%svgz;targets;tld;tmx;vbproj;vcxproj;vsixmanifest;wadl;wsdl;wsp;wxi;wxs;x3d;xacml;xaml;xamlx;%
				%xbrl;xht;xhtml;xlam;xlf;xliff;xlsm;xlsx;xltm;xltx;xml;xsd;xsl;xslt;xsp;xul"
		end

feature {NONE} -- Constants

	Default_internal_wild_cards: ARRAYED_LIST [STRING]
		once
			create Result.make_from_array (<< Dot_xml >>)
		end

	Dot_xml: STRING = "*.xml"

	Dot_xml_rels: STRING = "*.xml;*.rels"

	Extension_list: ARRAYED_LIST [STRING]
		once
			create Result.make (0)
			Result.append (new_xml_extensions.split (';'))
		end

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

end
