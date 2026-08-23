note
	description: "Types of XML document data and names"

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
			done: BOOLEAN
		do
			create Result.make_empty
			across Data_type_table as type until done loop
				if type ~ data_type then
					Result := @ type.key
					done := True
				end
			end
		end

feature {NONE} -- Constants

	Data_type_table: HASH_TABLE [INTEGER, STRING]
		once
			create Result.make_from_iterable_tuples (<<
				[Type_attribute,			"attribute"],	-- attribute value
				[Type_attribute_name,	"attrib-name"],-- attribute name
				[Type_cdata, 				"cdata"],		-- CDATA text content
				[Type_comment,				"comment"],		-- comment
				[Type_doctype,				"doctype"],		-- DOCTYPE declaration
				[Type_pi_name,				"pi-name"],		-- processing instruction name
				[Type_pi_data,				"pi-data"],		-- processing instruction data
				[Type_tag,					"tag"],			-- tag name (open element)
				[Type_text,					"text"],			-- text content
				[Type_xml_declaration,	"xml-decl"]		-- XML declaration parts: version, encoding, standalone
			>>)
		end

feature {NONE}	-- Constants

	Type_attribute: INTEGER = 1

	Type_attribute_name: INTEGER = 2

	Type_cdata: INTEGER = 3

	Type_comment: INTEGER = 4

	Type_doctype: INTEGER = 5

	Type_pi_name: INTEGER = 6

	Type_pi_data: INTEGER = 7

	Type_tag: INTEGER = 8

	Type_text: INTEGER = 9

	Type_xml_declaration: INTEGER = 10

end
