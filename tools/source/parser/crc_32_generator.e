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
	CRC_32_GENERATOR

inherit
	XT_XML_PARSER_BASE
		rename
			make as make_parser,
			Tok_attribute_value_s as Tok_attribute,
			Tok_data_chars as Tok_text,
			Tok_cdata_sect_open as Tok_cdata,
			Tok_end_tag as Tok_tag,
			Tok_pi as Tok_pi_value,
			Tok_name as Tok_pi_name
		redefine
			make_parser
		end

	XT_DEFAULT_PARSE_EVENTS
		rename
			on_cdata_section_close_ as on_cdata_section_close,
			on_tag_end_ as on_tag_end
		end

	PARSE_EVENT_CONSTANTS
		export
			{NONE} all
		end

	XT_EXPAT_COMPARABLE

	EL_CRC_32_CONSTANTS
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialisation

	make (a_data_type: INTEGER)
		do
			data_type := a_data_type
			make_parser
		end

	make_parser
		do
			Precursor
			create checksum
		end

feature -- Access

	checksum: EL_CRC_32_DIGEST
		-- CRC-32/ISO-HDLC checksum

feature -- Basic operations

	print_stats
		do
			IO.put_string ("Checksum for " + data_type_name (data_type) + ": " + checksum.out)
			IO.put_new_line
		end

feature -- Status change

	enable_trace
		do
			create {EL_TRACEABLE_CRC_32_DIGEST} checksum
		end

feature -- Status report

	trace_enabled: BOOLEAN

feature {NONE} -- Event handlers

	on_comment (area: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		do
			inspect data_type when Tok_comment then
				checksum.add_characters (area, start_index, end_index)
			else
			end
		end

	on_content (area: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		do
			inspect data_type
				when Tok_cdata then
					if in_cdata_section then
						checksum.add_characters (area, start_index, end_index)
					end
				when Tok_text then
					if not in_cdata_section then
						checksum.add_characters (area, start_index, end_index)
					end
			else
			end
		end

	on_tag_start (buf: like buffer; context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS; token: INTEGER)
		do
			inspect data_type
				when Tok_tag then
					checksum.add_string (context.name)

				when Tok_attribute then
					inspect token
						when Tok_start_tag_with_attributes, Tok_empty_element_with_attributes then
							attributes.append_values_to_crc_32 (checksum, buf, context.default_attribute_values)
					else
					-- perhaps there are some default values defined in DTD prolog
						if context.has_attributes and attributes.count = 0 then
							attributes.append_values_to_crc_32 (checksum, buf, context.default_attribute_values)
						end
					end
			else
			end
		end

	on_processing_instruction (buf: SPECIAL [CHARACTER]; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		do
			inspect data_type
				when Tok_pi_name then
					checksum.add_string (attributes.first_name (buf))
				when Tok_pi_value then
					attributes.append_first_value_to_crc_32 (checksum, buf)
			else
			end
		end

feature -- Factory

	new_benchmark (a_file_path: PATH; a_time_start: TIME; a_duration_ms, a_chunk_size: INTEGER): CRC_32_BENCHMARK
		do
			create Result.make (Current, a_file_path, a_time_start, a_duration_ms, a_chunk_size)
			Result.set_data_type (data_type)
		end

feature {NONE} -- Internal attributes

	data_type: INTEGER

end
