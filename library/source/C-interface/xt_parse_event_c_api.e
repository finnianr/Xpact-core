note
	description: "[
		C external callbacks for handler functions registered in `struct XML_ParserStruct'
		defined in `<xpact_private.h>'

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
	XT_PARSE_EVENT_C_API

inherit
	EL_C_API

feature {NONE} -- Data event call backs

	frozen call_on_cdata_section_end (callback, user_data: POINTER)
		-- typedef void (XMLCALL *XML_EndCdataSectionHandler) (void *userData);
		require
			callback_attached: is_attached (callback)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_EndCdataSectionHandler) $callback) ((void *) $user_data);"
		end

	frozen call_on_cdata_section_start (callback, user_data: POINTER)
		-- typedef void (XMLCALL *XML_StartCdataSectionHandler) (void *userData);
		require
			callback_attached: is_attached (callback)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_StartCdataSectionHandler) $callback) ((void *) $user_data);"
		end

	frozen call_on_comment (callback, user_data, text: POINTER)
		-- typedef void (XMLCALL *XML_CommentHandler) (
		--		void *userData, const XML_Char *data
		-- );
		require
			callback_attached: is_attached (callback)
			text_attached: is_attached (text)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_CommentHandler) $callback) ((void *) $user_data, (const char *) $text);"
		end

	frozen call_on_content (callback, user_data, text: POINTER; length: INTEGER)
		--	typedef void (XMLCALL *XML_CharacterDataHandler) (
		--		void *userData, const XML_Char *s, int len
		--	);	
		require
			callback_attached: is_attached (callback)
			text_attached: is_attached (text)
			non_negative_length: length >= 0
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_CharacterDataHandler) $callback) ((void *) $user_data, (const char *) $text, (int) $length);"
		end

	frozen call_on_element_end (callback, user_data, name: POINTER)
		--	typedef void (XMLCALL *XML_EndElementHandler) (
		--		void *userData, const XML_Char *name
		--	);	
		require
			callback_attached: is_attached (callback)
			name_attached: is_attached (name)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_EndElementHandler) $callback) ((void *) $user_data, (const char *) $name);"
		end

	frozen call_on_element_start (callback, user_data, name, attributes: POINTER)
		--	typedef void (XMLCALL *XML_StartElementHandler) (
		--		void *userData,
		--		const XML_Char *name,
		--		const XML_Char **atts
		--	);
		require
			callback_attached: is_attached (callback)
			name_attached: is_attached (name)
			attributes_attached: is_attached (attributes)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_StartElementHandler) $callback)(
					(void *) $user_data, (const char *) $name, (const char **) $attributes
				);
			]"
		end

	frozen call_on_processing_instruction (callback, user_data, target, data: POINTER)
			-- Invoke native `XML_ProcessingInstructionHandler'.
		require
			callback_attached: is_attached (callback)
			target_attached: is_attached (target)
			data_attached: is_attached (data)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_ProcessingInstructionHandler) $callback)(
					(void *) $user_data, (const char *) $target, (const char *) $data
				);
			]"
		end

feature {NONE} -- Parse event call backs

	frozen call_on_default (callback, user_data, s: POINTER; length: INTEGER)
			-- Invoke native `XML_DefaultHandler'.
			-- typedef void (XMLCALL *XML_DefaultHandler) (
			-- 	void *userData, const XML_Char *s, int len);
		require
			callback_attached: is_attached (callback)
			s_attached: is_attached (s)
			non_negative_length: length >= 0
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_DefaultHandler) $callback) ((void *) $user_data, (const char *) $s, (int) $length);"
		end

	frozen call_on_external_entity_reference (callback, parser, context, base, system_id, public_id: POINTER): INTEGER
			-- Invoke native `XML_ExternalEntityRefHandler'.
			-- typedef int (XMLCALL *XML_ExternalEntityRefHandler) (
			-- 	XML_Parser parser, const XML_Char *context, const XML_Char *base,
			-- 	const XML_Char *systemId, const XML_Char *publicId);
		require
			callback_attached: is_attached (callback)
			context_attached: is_attached (context)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_ExternalEntityRefHandler) $callback)(
					(XML_Parser) $parser, (const char *) $context, (const char *) $base,
					(const char *) $system_id, (const char *) $public_id
				)
			]"
		end

	frozen call_on_not_standalone (callback, user_data: POINTER): INTEGER
			-- Invoke native `XML_NotStandaloneHandler'.
			-- typedef int (XMLCALL *XML_NotStandaloneHandler) (void *userData);
		require
			callback_attached: is_attached (callback)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_NotStandaloneHandler) $callback) ((void *) $user_data)"
		end

	frozen call_on_skipped_entity (callback, user_data, entity_name: POINTER; is_parameter_entity: INTEGER)
			-- Invoke native `XML_SkippedEntityHandler'.
			-- typedef void (XMLCALL *XML_SkippedEntityHandler) (
			-- 	void *userData, const XML_Char *entityName, int is_parameter_entity);
		require
			callback_attached: is_attached (callback)
			entity_name_attached: is_attached (entity_name)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_SkippedEntityHandler) $callback)(
					(void *) $user_data, (const char *) $entity_name, (int) $is_parameter_entity
				);
			]"
		end

	frozen call_on_unknown_encoding (callback, encoding_handler_data, name, info: POINTER): INTEGER
			-- Invoke native `XML_UnknownEncodingHandler'.
			-- typedef int (XMLCALL *XML_UnknownEncodingHandler) (
			-- 	void *encodingHandlerData, const XML_Char *name, XML_Encoding *info);
		require
			callback_attached: is_attached (callback)
			name_attached: is_attached (name)
			info_attached: is_attached (info)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_UnknownEncodingHandler) $callback)(
					(void *) $encoding_handler_data, (const char *) $name, (XML_Encoding *) $info
				)
			]"
		end

feature {NONE} -- Declaration event call backs

	frozen call_on_attribute_list_declaration (
		callback, user_data, element_name, attribute_name, attribute_type, default_value: POINTER; is_required: INTEGER
	)
			-- Invoke native `XML_AttlistDeclHandler'.
		require
			callback_attached: is_attached (callback)
			elname_attached: is_attached (element_name)
			attname_attached: is_attached (attribute_name)
			att_type_attached: is_attached (attribute_type)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_AttlistDeclHandler) $callback)(
					(void *) $user_data, (const char *) $element_name, (const char *) $attribute_name,
					(const char *) $attribute_type, (const char *) $default_value, (int) $is_required
				);
			]"
		end

	frozen call_on_doctype_declaration_start (
		callback, user_data, doctype_name, system_id, public_id: POINTER; has_internal_subset: INTEGER
	)
			-- Invoke native `XML_StartDoctypeDeclHandler'.
		require
			callback_attached: is_attached (callback)
			doctype_name_attached: is_attached (doctype_name)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_StartDoctypeDeclHandler) $callback)(
					(void *) $user_data, (const char *) $doctype_name, (const char *) $system_id,
					(const char *) $public_id, (int) $has_internal_subset
				);
			]"
		end

	frozen call_on_element_declaration (callback, user_data, name, model: POINTER)
			-- Invoke native `XML_ElementDeclHandler'.
		require
			callback_attached: is_attached (callback)
			name_attached: is_attached (name)
			model_attached: is_attached (model)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_ElementDeclHandler) $callback)(
					(void *) $user_data, (const char *) $name, (XML_Content *) $model
				);
			]"
		end

	frozen call_on_entity_declaration (
		callback, user_data, entity_name: POINTER; is_parameter_entity: INTEGER; value: POINTER; value_length: INTEGER
		base, system_id, public_id, notation_name: POINTER
	)
			-- Invoke native `XML_EntityDeclHandler'.
		require
			callback_attached: is_attached (callback)
			entity_name_attached: is_attached (entity_name)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_EntityDeclHandler) $callback)(
					(void *) $user_data, (const char *) $entity_name, (int) $is_parameter_entity,
					(const char *) $value, (int) $value_length, (const char *) $base,
					(const char *) $system_id, (const char *) $public_id, (const char *) $notation_name
				);
			]"
		end

	frozen call_on_namespace_declaration_end (callback, user_data, prefix: POINTER)
			-- Invoke native `XML_EndNamespaceDeclHandler'.
		require
			callback_attached: is_attached (callback)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_EndNamespaceDeclHandler) $callback) ((void *) $user_data, (const char *) $prefix);"
		end

	frozen call_on_namespace_declaration_start (callback, user_data, prefix, uri: POINTER)
			-- Invoke native `XML_StartNamespaceDeclHandler'.
		require
			callback_attached: is_attached (callback)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_StartNamespaceDeclHandler) $callback)(
					(void *) $user_data, (const char *) $prefix, (const char *) $uri
				);
			]"
		end

	frozen call_on_notation_declaration (callback, user_data, notation_name, base, system_id, public_id: POINTER)
			-- Invoke native `XML_NotationDeclHandler'.
		require
			callback_attached: is_attached (callback)
			notation_name_attached: is_attached (notation_name)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_NotationDeclHandler) $callback)(
					(void *) $user_data, (const char *) $notation_name, (const char *) $base,
					(const char *) $system_id, (const char *) $public_id
				);
			]"
		end

	frozen call_on_unparsed_entity_declaration (
		callback, user_data, entity_name, base, system_id, public_id, notation_name: POINTER
	)
			-- Invoke native `XML_UnparsedEntityDeclHandler'.
			-- typedef void (XMLCALL *XML_UnparsedEntityDeclHandler) (
			-- 	void *userData, const XML_Char *entityName, const XML_Char *base,
			-- 	const XML_Char *systemId, const XML_Char *publicId, const XML_Char *notationName);
		require
			callback_attached: is_attached (callback)
			entity_name_attached: is_attached (entity_name)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_UnparsedEntityDeclHandler) $callback)(
					(void *) $user_data, (const char *) $entity_name, (const char *) $base,
					(const char *) $system_id, (const char *) $public_id, (const char *) $notation_name
				);
			]"
		end

	frozen call_on_xml_declaration (callback, user_data, version, encoding: POINTER; standalone: INTEGER)
			-- Invoke native `XML_XmlDeclHandler'.
		require
			callback_attached: is_attached (callback)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				((XML_XmlDeclHandler) $callback)(
					(void *) $user_data, (const char *) $version, (const char *) $encoding, (int) $standalone
				);
			]"
		end

feature {NONE} -- Data event handlers

	frozen c_on_cdata_section_end (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->endCdataSectionHandler"
		end

	frozen c_on_cdata_section_start (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->startCdataSectionHandler"
		end

	frozen c_on_comment (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->commentHandler"
		end

	frozen c_on_content (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->characterDataHandler"
		end

	frozen c_on_element_end (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->endElementHandler"
		end

	frozen c_on_element_start (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->startElementHandler"
		end

	frozen c_on_processing_instruction (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->processingInstructionHandler"
		end

feature {NONE} -- Other parse event handlers

	frozen c_on_default (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->defaultHandler"
		end

	frozen c_on_external_entity_reference (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->externalEntityRefHandler"
		end

	frozen c_on_not_standalone (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->notStandaloneHandler"
		end

	frozen c_on_skipped_entity (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->skippedEntityHandler"
		end

	frozen c_on_unknown_encoding (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->unknownEncodingHandler"
		end

feature {NONE} -- Declaration event handlers

	frozen c_on_attribute_list_declaration (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->attlistDeclHandler"
		end

	frozen c_on_doctype_declaration_start (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->startDoctypeDeclHandler"
		end

	frozen c_on_element_declaration (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->elementDeclHandler"
		end

	frozen c_on_entity_declaration (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->entityDeclHandler"
		end

	frozen c_on_namespace_declaration_end (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->endNamespaceDeclHandler"
		end

	frozen c_on_namespace_declaration_start (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->startNamespaceDeclHandler"
		end

	frozen c_on_notation_declaration (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->notationDeclHandler"
		end

	frozen c_on_unparsed_entity_declaration (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->unparsedEntityDeclHandler"
		end

	frozen c_on_xml_declaration (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->xmlDeclHandler"
		end

end
