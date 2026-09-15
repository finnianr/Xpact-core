note
	description: "[
		Dispatch parse events as C callbacks to registered handler functions defined in `struct XML_ParserStruct'.
		
		Include File:
		 	contrib/xpact/include/xpact_private.h
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-09 15:37:00 GMT (Wednesday 9th September 2026)"
	revision: "1"

class
	XT_PARSE_EVENT_DISPATCHER

inherit
	XT_XML_PARSER_BASE
		redefine
			make
		end

	XT_PARSE_EVENT_C_API

create
	make

feature {NONE} -- Initialization

	make (parse_data: MANAGED_POINTER; is_uri_mapped: BOOLEAN)
		do
			Precursor (parse_data, is_uri_mapped)
			create empty_attributes.make_filled (default_pointer, 1)
		end

feature {NONE} -- Parse event handlers

	on_cdata_section_start (parse_data: POINTER)
		-- typedef void (XMLCALL *XML_StartCdataSectionHandler) (void *userData);
		local
			ptr: POINTER
		do
			ptr := c_on_CDATA_section_start (parse_data)
			if is_attached (ptr) then
				call_on_cdata_section_start (ptr, c_user_data (parse_data))
			end
		end

	on_cdata_section_end (parse_data: POINTER)
		-- typedef void (XMLCALL *XML_EndCdataSectionHandler) (void *userData);
		local
			ptr: POINTER
		do
			ptr := c_on_cdata_section_end (parse_data)
			if is_attached (ptr) then
				call_on_cdata_section_end (ptr, c_user_data (parse_data))
			end
		end

	on_comment (buf: like buffer; start_index, end_index: INTEGER; parse_data: POINTER)
		-- typedef void (XMLCALL *XML_CommentHandler) (
		--		void *userData, const XML_Char *data
		-- );
		local
			ptr: POINTER
		do
			ptr := c_on_comment (parse_data)
			if is_attached (ptr) then
				null_terminate (buf, end_index, parse_data)
				call_on_comment (ptr, c_user_data (parse_data), buf.item_address (start_index))
				undo_null_termination (buf, parse_data)
			end
		end

	on_content (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; parse_data: POINTER)
		--	typedef void (XMLCALL *XML_CharacterDataHandler) (
		--		void *userData, const XML_Char *s, int len
		--	);	
		local
			ptr: POINTER
		do
			ptr := c_on_content (parse_data)
			if is_attached (ptr) then
				set_active_callback_kind (parse_data, Callback_character_data)
				call_on_content (ptr, c_user_data (parse_data), buffer.item_address (start_index), end_index - start_index + 1)
				set_active_callback_kind (parse_data, Callback_none)
			end
		end

	on_element_end (name: STRING; parse_data: POINTER)
		--	typedef void (XMLCALL *XML_EndElementHandler) (
		--		void *userData, const XML_Char *name
		--	);	
		local
			ptr: POINTER
		do
			ptr := c_on_element_end (parse_data)
			if is_attached (ptr) then
				call_on_element_end (ptr, c_user_data (parse_data), name.area.base_address)
			end
		end

	on_element_start (
		buf: like buffer; context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_LIST; token: INTEGER; parse_data: POINTER
	)
		--	typedef void (XMLCALL *XML_StartElementHandler) (
		--		void *userData, const XML_Char *name, const XML_Char **atts
		--	);
		require else
			null_terminated_name: context.name.area [context.name.count] = '%U'
		local
			ptr: POINTER; c_string_array: SPECIAL [POINTER]; has_attributes: BOOLEAN
		do
			ptr := c_on_element_start (parse_data)
			if is_attached (ptr) and then attached context.name.area as name_area then
				inspect token when Tok_start_tag_with_attributes, Tok_empty_element_with_attributes then
					has_attributes := True
				else
				-- perhaps there were some default values defined in a DTD prolog
					inspect attributes.count when 0 then
						has_attributes := context.has_attributes and then context.default_attribute_values.count > 0
					else
						has_attributes := False
					end
				end
				if has_attributes then
					attributes.null_terminate_values (buf)
					c_string_array := attributes.to_c_array (buf, context.default_attribute_values)
					call_on_element_start (ptr, c_user_data (parse_data), name_area.base_address, c_string_array.base_address)
					attributes.undo_null_terminated_values (buf)
				else
					call_on_element_start (ptr, c_user_data (parse_data), name_area.base_address, Empty_attributes.base_address)
				end
			end
		ensure then
			buffer_unchanged: attributes.upper_plus_1_characters (buf) ~ old attributes.upper_plus_1_characters (buf)
		end

	on_processing_instruction (
		buf: like buffer; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_LIST; parse_data: POINTER
	)
		-- typedef void (XMLCALL *XML_ProcessingInstructionHandler) (
		--		void *userData, const XML_Char *target, const XML_Char *data
		--	);

		require else
			buffer_big_enough: buf.valid_index (end_index + 1)
		local
			ptr: POINTER; c_string_array: SPECIAL [POINTER]
		do
			ptr := c_on_processing_instruction (parse_data)
			if is_attached (ptr) then
				if attributes.is_empty then
					null_terminate (buf, end_index, parse_data)
					call_on_processing_instruction (ptr, c_user_data (parse_data), buf.item_address (start_index), default_pointer)
					undo_null_termination (buf, parse_data)

				else
					attributes.null_terminate_values (buf)
					c_string_array := attributes.first_name_value_c_array (buf)
					call_on_processing_instruction (ptr, c_user_data (parse_data), c_string_array [0], c_string_array [1])
					attributes.undo_null_terminated_values (buf)
				end
			end
		ensure then
			buffer_unchanged: attributes.upper_plus_1_characters (buf) ~ old attributes.upper_plus_1_characters (buf)
		end

feature {NONE} -- Declaration event handlers

	on_attribute_list_declaration (
		element_name, attribute_name, attribute_type: STRING; default_value: detachable STRING
		is_required: BOOLEAN; parse_data: POINTER
	)
		-- typedef void (XMLCALL *XML_AttlistDeclHandler)(
		--   void *userData, const XML_Char *elname, const XML_Char *attname,
		--   const XML_Char *att_type, const XML_Char *default, int isrequired
		-- );
		local
			ptr: POINTER
		do
			ptr := c_on_attribute_list_declaration (parse_data)
			if is_attached (ptr) then
				call_on_attribute_list_declaration (
					ptr, c_user_data (parse_data), element_name.area.base_address, attribute_name.area.base_address,
					attribute_type.area.base_address, base_address (default_value), is_required.to_integer
				)
			end
		end

	on_doctype_declaration_start (parts_list: XT_DECLARATION_PARTS_LIST; has_internal_subset: BOOLEAN; parse_data: POINTER)
		-- typedef void (XMLCALL *XML_StartDoctypeDeclHandler)(
		--		void *userData, const XML_Char *doctypeName, const XML_Char *sysid, const XML_Char *pubid,
		--		int has_internal_subset
		-- );
		local
			ptr, system_id, public_id: POINTER
		do
			ptr := c_on_doctype_declaration_start (parse_data)
			if is_attached (ptr) and then attached doctype_identifiers as identifier then
				if identifier.formal_public /= Empty_string then
					public_id := identifier.formal_public.area.base_address
				end
				if identifier.uri /= Empty_string then
					system_id := identifier.uri.area.base_address
				end
				call_on_doctype_declaration_start (
					ptr, c_user_data (parse_data), parts_list.name.area.base_address, system_id, public_id,
					has_internal_subset.to_integer
				)
			end
		end

	on_element_declaration (name: STRING; model: XT_ELEMENT_PARTICLE; parse_data: POINTER)
		-- typedef void (XMLCALL *XML_ElementDeclHandler)(
		--		void *userData, const XML_Char *name, XML_Content *model
		-- );
		local
			ptr: POINTER
		do
			ptr := c_on_element_declaration (parse_data)
			if is_attached (ptr) then
			-- `model.self_ptr' is field-for-field compatible with `XML_Content *'.
				call_on_element_declaration (ptr, c_user_data (parse_data), name.area.base_address, model.self_ptr)
			end
		end

	on_entity_declaration (
		entity_name: STRING; value, system_id, public_id, notation_name: detachable STRING
		is_parameter_entity: BOOLEAN; parse_data: POINTER
	)
		-- typedef void(XMLCALL *XML_EntityDeclHandler)(
		-- 	void *userData, const XML_Char *entityName, int is_parameter_entity,
		-- 	const XML_Char *value, int value_length, const XML_Char *base,
		-- 	const XML_Char *systemId, const XML_Char *publicId,
		-- 	const XML_Char *notationName
		--	);
		local
			ptr, value_ptr: POINTER; value_count: INTEGER
		do
			ptr := c_on_entity_declaration (parse_data)
			if is_attached (ptr) then
				if attached value as l_value then
					value_ptr := l_value.area.base_address
					value_count := l_value.count
				end
				call_on_entity_declaration (
					ptr, c_user_data (parse_data), entity_name.area.base_address, is_parameter_entity.to_integer,
					value_ptr, value_count, c_base (parse_data), base_address (system_id),
					base_address (public_id), base_address (notation_name)
				)
			end
		end

	on_notation_declaration (name: STRING; system_id, public_id: detachable STRING; parse_data: POINTER)
		-- typedef void (XMLCALL *XML_NotationDeclHandler)(
		-- 	void *userData, const XML_Char *notationName,
		--		const XML_Char *base, const XML_Char *systemId, const XML_Char *publicId
		-- );
		local
			ptr: POINTER
		do
			ptr := c_on_notation_declaration (parse_data)
			if is_attached (ptr) then
				call_on_notation_declaration (
					ptr, c_user_data (parse_data), name.area.base_address, c_base (parse_data),
					base_address (system_id), base_address (public_id)
				)
			end
		end

	on_xml_declaration (buf: like buffer; attributes: XT_ATTRIBUTE_LIST; parse_data: POINTER)
		-- typedef void (XMLCALL *XML_XmlDeclHandler)(
		-- 	void *userData, const XML_Char *version, const XML_Char *encoding, int standalone
		-- );
		local
			ptr: POINTER; c_string_array: SPECIAL [POINTER]
		do
			ptr := c_on_xml_declaration (parse_data)
			if is_attached (ptr) then
				attributes.null_terminate_values (buf)
				c_string_array := attributes.to_version_encoding_c_array (buf)
				call_on_xml_declaration (
					ptr, c_user_data (parse_data), c_string_array [0], c_string_array [1], attributes.standalone_code (buf)
				)
				attributes.undo_null_terminated_values (buf)
			end
		ensure then
			buffer_unchanged: attributes.upper_plus_1_characters (buf) ~ old attributes.upper_plus_1_characters (buf)
		end

feature {NONE} -- Implementation

	base_address (a_str: detachable STRING): POINTER
		do
			if attached a_str as str then
				Result := str.area.base_address
			end
		end

	null_terminate (buf: like buffer; end_index: INTEGER; parse_data: POINTER)
		require
			buffer_big_enough: buf.valid_index (end_index + 1)
		local
			null_index: INTEGER
		do
			null_index := end_index + 1
			set_null_swap (parse_data, buf [null_index])
			buf [null_index] := '%U'
		end

	undo_null_termination (buf: like buffer; parse_data: POINTER)
		require
			buffer_big_enough: buf.valid_index (c_null_index (parse_data))
			null_terminated: buf [c_null_index (parse_data)] = '%U'
		do
			buf [c_null_index (parse_data)] := c_null_swap (parse_data)
		end

feature {NONE} -- Internal attributes

	empty_attributes: SPECIAL [POINTER]

feature {NONE} -- Constants

	Callback_none: INTEGER = 0
		-- No callback is currently dispatching.

	Callback_character_data: INTEGER = 1
	 -- character-data callback is currently dispatching.

end
