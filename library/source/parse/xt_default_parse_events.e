note
	description: "Default events for implementing ${XPACT_INCREMENTAL_PARSER}"
	notes: "[
		**EXAMPLE CODE**
		
			inherit
				XPACT_INCREMENTAL_PARSER

				XT_DEFAULT_PARSE_EVENTS
					rename
						on_comment_ as on_comment,
						on_content_ as on_content,
						on_tag_attributes as on_tag_attributes,
						on_tag_end_ as on_tag_end
					end
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 18:20:41 GMT (Saturday 20th June 2026)"
	revision: "1"

deferred class
	XT_DEFAULT_PARSE_EVENTS

feature {NONE} -- Event handlers

	on_cdata_section_close_
		do
		end

	on_comment_ (buf: like buffer; lower, upper: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		do
		end

	on_content_ (buf: like buffer; a_start, a_end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		do
		end

	on_tag_end_ (name: STRING_8)
		do
		end

	on_tag_start_ (buf: like buffer; context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS; token: INTEGER)
		do
		end

	on_processing_instruction_ (buf: like buffer; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		do
		end

	on_xml_declaration_ (buf: like buffer; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		do
		end

feature {NONE} -- Implementation

	buffer: SPECIAL [CHARACTER_8]
		deferred
		end

end
