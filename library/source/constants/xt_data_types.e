note
	description: "Types/dimensions of XML document data and names"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-22 14:08:00 GMT (Saturday 22th August 2026)"
	revision: "1"

class
	XT_DATA_TYPES

feature {NONE} -- Implementation

	data_type_name (data_type: INTEGER): STRING
		local
			s: XT_STRING_8_ROUTINES
		do
			if attached Data_type_name_table [data_type] as name then
				Result := name
			else
				Result := s.Empty_string
			end
		end

feature {NONE} -- Constants

	Data_type_table: HASH_TABLE [INTEGER, STRING]
		once
			create Result.make_from_iterable_tuples (<<
				[Type_attribute,				"attribute"],	-- attribute name and value
				[Type_cdata, 					"cdata"],		-- CDATA text content
				[Type_comment,					"comment"],		-- comment
				[Type_decl_attribute_list,	"attlist"],		-- ATTLIST declaration
				[Type_decl_doctype,			"doctype"],		-- DOCTYPE declaration
				[Type_decl_element,			"element"],		-- ELEMENT declaration
				[Type_decl_entity,			"entity"],		-- ENTITY declaration
				[Type_decl_notation,			"notation"],	-- NOTATION declaration
				[Type_processing,				"processing"],	-- processing instruction name and data
				[Type_tag,						"tag"],			-- tag name (open element)
				[Type_text,						"text"],			-- text content
				[Type_xml_declaration,		"xml-decl"],	-- XML declaration parts: version, encoding, standalone
				[Type_xmlns_declaration,	"xmlns-decl"]	-- XML namespace declaration and scope end
			>>)
		end

	Data_type_name_table: HASH_TABLE [STRING, INTEGER]
		once
			create Result.make (Data_type_table.count)
			across Data_type_table as type loop
				Result.extend (@ type.key, type)
			end
		end

feature {NONE}	-- Constants

	Type_attribute: INTEGER = 1

	Type_cdata: INTEGER = 2

	Type_comment: INTEGER = 3

	Type_decl_attribute_list: INTEGER = 4

	Type_decl_doctype: INTEGER = 5

	Type_decl_element: INTEGER = 6

	Type_decl_entity: INTEGER = 7

	Type_decl_notation: INTEGER = 8

	Type_processing: INTEGER = 9

	Type_tag: INTEGER = 10

	Type_text: INTEGER = 11

	Type_xml_declaration: INTEGER = 12

	Type_xmlns_declaration: INTEGER = 13
end
