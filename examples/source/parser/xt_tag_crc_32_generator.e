note
	description: "[
		Generate CRC-32 for one of XML document characteristics
		
		1. tag name
		2. attribute value
		3. cdata
		4. text
		5. comment
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-06-29 6:31:14 GMT (Monday 29th June 2026)"
	revision: "1"

class
	XT_TAG_CRC_32_GENERATOR

inherit
	XT_XML_PARSER
		rename
			make as make_parser,
			Tok_data_chars as Tok_text,
			Tok_cdata_sect_open as Tok_cdata,
			Tok_end_tag as Tok_tag,
			Tok_attribute_value_s as Tok_attribute
		end

	XT_DOCUMENT_STATS

	EL_CRC_32_CONSTANTS
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialisation

	make (a_data_type: INTEGER; a_data_type_name: STRING)
		do
			make_parser
			data_type := a_data_type; data_type_name := a_data_type_name
			create checksum
		end

feature -- Basic operations

	print_stats
		do
			IO.put_string ("Checksum for " + data_type_name + ": " + checksum.out)
			IO.put_new_line
		end

feature {NONE} -- Event handlers

	on_comment (text: C_STRING_8)
		do
			inspect data_type
				when Tok_comment then
					checksum.add_bytes (text.area, text.count)
			else
			end
		end

	on_content (text_intervals: XT_TEXT_DATA_BUFFER_INTERVALS)
		do
			inspect data_type
				when Tok_cdata, Tok_text then
					text_intervals.append_to_crc_32 (checksum, buffer)
			else
			end
		end

	on_tag_end (name: STRING_8)
		do
		end

	on_tag_start (name: STRING_8; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		do
			inspect data_type
				when Tok_tag then
					checksum.add_string (name)

				when Tok_attribute then
					attributes.append_to_crc_32 (checksum, buffer)
			else
			end
		end

feature {NONE} -- Internal attributes

	data_type: INTEGER

	data_type_name: STRING

	checksum: EL_CRC_32_DIGEST
		-- CRC-32/ISO-HDLC checksum

end
