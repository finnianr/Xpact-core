note
	description: "Count occurrences of tags in a document and display in order of highest count to lowest"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 18:21:11 GMT (Saturday 20th June 2026)"
	revision: "1"

class
	TAG_COUNTER

inherit
	XT_XML_PARSER_BASE
		rename
			make as make_parser,
			make_default as make
		redefine
			make, put_status
		end

	XT_DEFAULT_PARSE_EVENTS
		rename
			on_attribute_list_declaration_ as on_attribute_list_declaration,
			on_cdata_section_start_ as on_cdata_section_start,
			on_cdata_section_end_ as on_cdata_section_end,
			on_comment_ as on_comment,
			on_content_ as on_content,
			on_doctype_declaration_start_ as on_doctype_declaration_start,
			on_element_declaration_ as on_element_declaration,
			on_entity_declaration_ as on_entity_declaration,
			on_notation_declaration_ as on_notation_declaration,
			on_element_end_ as on_element_end,
			on_processing_instruction_ as on_processing_instruction,
			on_xml_declaration_ as on_xml_declaration
		end

	XT_EXPAT_COMPARABLE_PARSER

create
	make

feature {NONE} -- Initialisation

	make
		do
			create tag_occurrence_table.make (100)
			Precursor
		end

feature -- Basic operations

	put_status (output: IO_MEDIUM)
		do
			output.put_string ("Tags sorted in order of occurrence count (Highest first)")
			output.put_new_line
			output.put_new_line
			across tag_occurrence_table.sorted_occurrence_list (False) as tag_count loop
				tag_count.put_status (output)
			end
			output.put_new_line
			name_cache.put_status (output)
		end

feature {NONE} -- Event handlers

	on_element_start (
		buf: like buffer; context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_LIST; token: INTEGER; parse_data: POINTER
	)
		do
			tag_occurrence_table.put (context.name)
		end

feature -- Factory

	new_benchmark (a_file_path: PATH; a_time_start: TIME; a_duration_ms, a_chunk_size: INTEGER): TAG_COUNTER_BENCHMARK
		do
			create Result.make (Current, a_file_path, a_time_start, a_duration_ms, a_chunk_size)
		end

feature {NONE} -- Internal attributes

	tag_occurrence_table: XT_NAME_OCCURRENCE_COUNT_TABLE

end
