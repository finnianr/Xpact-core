note
	description: "[
		Generate CRC-32 for one of XML document data types listed in ${XT_DATA_TYPES}.Data_type_table
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-06-29 6:31:14 GMT (Monday 29th June 2026)"
	revision: "1"

class
	XT_CRC_32_GENERATOR

inherit
	XT_XML_PARSER_BASE
		rename
			make as make_parser
		redefine
			make_parser, reset
		end

	XT_DEFAULT_PARSE_EVENTS
		rename
			on_cdata_section_close_ as on_cdata_section_close,
			on_tag_end_ as on_tag_end
		end

	XT_EXPAT_COMPARABLE_PARSER
		rename
			checksum as checksum_value
		redefine
			checksum_value
		end

	EL_CRC_32_CONSTANTS
		export
			{NONE} all
		end

	XT_DATA_TYPES

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

	checksum_value: NATURAL
		-- CRC-32/ISO-HDLC checksum
		do
			Result := checksum.value
		end

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

	reset
		do
			Precursor
			checksum.reset
		end

feature -- Status report

	trace_enabled: BOOLEAN

feature {NONE} -- Event handlers

	on_attribute_list_declaration (
		element_name, attribute_name, attribute_type: STRING; default_value: detachable STRING
		is_required: BOOLEAN
	)
		do
			inspect data_type when Type_decl_attribute_list then
				if attached checksum as crc then
					crc.add_string (element_name)
					crc.add_string (attribute_name)
					crc.add_string (attribute_type)
					if attached default_value as value then
						crc.add_string (value)
					end
					crc.add_boolean (is_required)
				end
			else
			end
		end

	on_comment (area: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_LIST)
		do
			inspect data_type when Type_comment then
				checksum.add_characters (area, start_index, end_index)
			else
			end
		end

	on_content (area: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_LIST)
		do
			inspect data_type
				when Type_cdata then
					if in_cdata_section then
						checksum.add_characters (area, start_index, end_index)
					end
				when Type_text then
					if not in_cdata_section then
						checksum.add_characters (area, start_index, end_index)
					end
			else
			end
		end

	on_doctype_declaration_start (parts_list: XT_DECLARATION_PARTS_LIST; has_internal_subset: BOOLEAN)
		local
			i: INTEGER
		do
			inspect data_type when Type_decl_doctype then
				if attached checksum as crc then
					from i := 1 until i > parts_list.count loop
						crc.add_string (parts_list [i])
						i := i + 1
					end
					crc.add_boolean (has_internal_subset)
				end
			else end
		end

	on_entity_declaration (
		entity_name: STRING; value, a_base, system_id, public_id, notation_name: detachable STRING
		is_parameter_entity: BOOLEAN
	)
		-- typedef void(XMLCALL *XML_EntityDeclHandler)(
		-- 	void *userData, const XML_Char *entityName, int is_parameter_entity,
		-- 	const XML_Char *value, int value_length, const XML_Char *base,
		-- 	const XML_Char *systemId, const XML_Char *publicId,
		-- 	const XML_Char *notationName);
		do
			inspect data_type when Type_decl_entity then
				if attached checksum as crc then
					crc.add_characters (entity_name.area, 1, entity_name.count - 2)
					crc.add_boolean (is_parameter_entity)
					if attached value as str then
						crc.add_string (str)
						crc.add_integer_32 (str.count)
					end
					if attached a_base as str then
						crc.add_string (str)
					end
					if attached system_id as str then
						crc.add_string (str)
					end
					if attached public_id as str then
						crc.add_string (str)
					end
					if attached notation_name as str then
						crc.add_string (str)
					end
				end
			else end
		end

	on_notation_declaration (name: STRING; a_base, system_id, public_id: detachable STRING)
		-- typedef void(XMLCALL *XML_NotationDeclHandler)(void *userData,
		-- const XML_Char *notationName, const XML_Char *base, const XML_Char *systemId, const XML_Char *publicId);
		do
			inspect data_type when Type_decl_notation then
				if attached checksum as crc then
					crc.add_string (name)
					if attached a_base as str then
						crc.add_string (str)
					end
					if attached system_id as str then
						crc.add_string (str)
					end
					if attached public_id as str then
						crc.add_string (str)
					end
				end
			else end
		end

	on_tag_start (buf: like buffer; context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_LIST; token: INTEGER)
		do
			inspect data_type
				when Type_tag then
					checksum.add_string (context.name)

				when Type_attribute, Type_attribute_name then
					inspect token when Tok_start_tag_with_attributes, Tok_empty_element_with_attributes then
						attributes.append_to_crc_32 (buf, context.default_attribute_values, data_type, checksum)
					else
					-- perhaps there are some default values defined in DTD prolog
						inspect attributes.count when 0 then
							if context.has_attributes then
								attributes.append_to_crc_32 (buf, context.default_attribute_values, data_type, checksum)
							end
						else end
					end
			else
			end
		end

	on_processing_instruction (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_LIST)
		do
			inspect data_type
				when Type_pi_name then
					if attributes.is_empty then
						checksum.add_characters (buf, start_index, end_index)
					else
						checksum.add_string (attributes.first_name)
					end
				when Type_pi_data then
					if attributes.count > 0 then
						attributes.append_first_value_to_crc_32 (buf, checksum)
					end
			else
			end
		end

	on_xml_declaration (buf: like buffer; attributes: XT_ATTRIBUTE_LIST)
		do
			inspect data_type when Type_xml_declaration then
				attributes.append_xml_declaration_to_crc_32 (buf, checksum)
			else end
		end

feature -- Factory

	new_benchmark (a_file_path: PATH; a_time_start: TIME; a_duration_ms, a_chunk_size: INTEGER): XT_CRC_32_BENCHMARK
		do
			create Result.make (Current, a_file_path, a_time_start, a_duration_ms, a_chunk_size)
			Result.set_data_type (data_type)
		end

feature {NONE} -- Internal attributes

	data_type: INTEGER

end
