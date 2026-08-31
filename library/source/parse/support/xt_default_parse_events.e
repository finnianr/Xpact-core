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

	on_attribute_list_declaration_ (
		element_name, attribute_name, attribute_type: STRING; default_value: detachable STRING
		is_required: BOOLEAN
	)
		-- typedef void(XMLCALL *XML_AttlistDeclHandler)(
		--   void *userData, const XML_Char *elname, const XML_Char *attname,
		--   const XML_Char *att_type, const XML_Char *dflt, int isrequired);
		do
		end

	on_cdata_section_close_
		do
		end

	on_comment_ (buf: like buffer; lower, upper: INTEGER; attributes: XT_ATTRIBUTE_LIST)
		do
		end

	on_content_ (buf: like buffer; a_start, a_end_index: INTEGER; attributes: XT_ATTRIBUTE_LIST)
		do
		end

	on_doctype_declaration_start_ (parts_list: XT_DECLARATION_PARTS_LIST; has_internal_subset: BOOLEAN)
		do
		end

	on_entity_declaration_ (
		entity_name: STRING; value, base, system_id, public_id, notation_name: detachable STRING
		is_parameter_entity: BOOLEAN
	)
		-- typedef void(XMLCALL *XML_EntityDeclHandler)(
		-- 	void *userData, const XML_Char *entityName, int is_parameter_entity,
		-- 	const XML_Char *value, int value_length, const XML_Char *base,
		-- 	const XML_Char *systemId, const XML_Char *publicId,
		-- 	const XML_Char *notationName);
		do
		end

	on_tag_end_ (name: STRING_8)
		do
		end

	on_tag_start_ (buf: like buffer; context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_LIST; token: INTEGER)
		do
		end

	on_processing_instruction_ (buf: like buffer; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_LIST)
		do
		end

	on_xml_declaration_ (buf: like buffer; attributes: XT_ATTRIBUTE_LIST)
		do
		end

feature {NONE} -- Implementation

	buffer: SPECIAL [CHARACTER_8]
		deferred
		end

end
