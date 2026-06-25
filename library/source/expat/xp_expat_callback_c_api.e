note
	description: "eXpat C calls"

class
	XP_EXPAT_CALLBACK_C_API

feature {NONE} -- C Externals

	content_struct_size: INTEGER
			-- Size of native `XML_Content' under the C ABI used by `include/xpact.h'.
		external
			"C inline"
		alias
			"typedef struct { int type; int quant; char *name; unsigned int numchildren; void *children; } XPACT_EiffelContentModel; return (EIF_INTEGER) sizeof (XPACT_EiffelContentModel);"
		end

	c_malloc (a_size: INTEGER): POINTER
			-- Allocate native memory that `XML_FreeContentModel' can release with the default allocator.
		require
			non_negative_size: a_size >= 0
		external
			"C inline use <stdlib.h>"
		alias
			"return (EIF_POINTER) malloc ((size_t) $a_size);"
		end

	put_content_model_node (a_base: POINTER; a_index, a_type, a_quant: INTEGER; a_name: POINTER; a_numchildren, a_first_child_index: INTEGER)
			-- Write one native content model node.
		require
			base_attached: a_base /= default_pointer
			valid_index: a_index >= 0
			non_negative_children: a_numchildren >= 0
			valid_child_index: a_first_child_index >= -1
		external
			"C inline"
		alias
			"typedef struct { int type; int quant; char *name; unsigned int numchildren; void *children; } XPACT_EiffelContentModel; XPACT_EiffelContentModel *items = (XPACT_EiffelContentModel *) $a_base; items[$a_index].type = (int) $a_type; items[$a_index].quant = (int) $a_quant; items[$a_index].name = (char *) $a_name; items[$a_index].numchildren = (unsigned int) $a_numchildren; items[$a_index].children = ($a_first_child_index >= 0) ? (void *) &items[$a_first_child_index] : (void *) 0;"
		end

	call_start_element_callback (a_callback, a_user_data, a_name, a_attributes: POINTER)
			-- Invoke native `XML_StartElementHandler'.
		require
			callback_attached: a_callback /= default_pointer
			name_attached: a_name /= default_pointer
			attributes_attached: a_attributes /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, const char **)) $a_callback) ((void *) $a_user_data, (const char *) $a_name, (const char **) $a_attributes);"
		end

	call_end_element_callback (a_callback, a_user_data, a_name: POINTER)
			-- Invoke native `XML_EndElementHandler'.
		require
			callback_attached: a_callback /= default_pointer
			name_attached: a_name /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *)) $a_callback) ((void *) $a_user_data, (const char *) $a_name);"
		end

	call_character_data_callback (a_callback, a_user_data, a_text: POINTER; a_length: INTEGER)
			-- Invoke native `XML_CharacterDataHandler'.
		require
			callback_attached: a_callback /= default_pointer
			text_attached: a_text /= default_pointer
			non_negative_length: a_length >= 0
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, int)) $a_callback) ((void *) $a_user_data, (const char *) $a_text, (int) $a_length);"
		end

	call_processing_instruction_callback (a_callback, a_user_data, a_target, a_data: POINTER)
			-- Invoke native `XML_ProcessingInstructionHandler'.
		require
			callback_attached: a_callback /= default_pointer
			target_attached: a_target /= default_pointer
			data_attached: a_data /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, const char *)) $a_callback) ((void *) $a_user_data, (const char *) $a_target, (const char *) $a_data);"
		end

	call_xml_decl_callback (a_callback, a_user_data, a_version, a_encoding: POINTER; a_standalone: INTEGER)
			-- Invoke native `XML_XmlDeclHandler'.
		require
			callback_attached: a_callback /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, const char *, int)) $a_callback) ((void *) $a_user_data, (const char *) $a_version, (const char *) $a_encoding, (int) $a_standalone);"
		end

	call_comment_callback (a_callback, a_user_data, a_text: POINTER)
			-- Invoke native `XML_CommentHandler'.
		require
			callback_attached: a_callback /= default_pointer
			text_attached: a_text /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *)) $a_callback) ((void *) $a_user_data, (const char *) $a_text);"
		end

	call_cdata_section_callback (a_callback, a_user_data: POINTER)
			-- Invoke native CDATA start/end handler.
		require
			callback_attached: a_callback /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *)) $a_callback) ((void *) $a_user_data);"
		end

	call_default_callback (a_callback, a_user_data, a_text: POINTER; a_length: INTEGER)
			-- Invoke native `XML_DefaultHandler'.
		require
			callback_attached: a_callback /= default_pointer
			text_attached: a_text /= default_pointer
			non_negative_length: a_length >= 0
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, int)) $a_callback) ((void *) $a_user_data, (const char *) $a_text, (int) $a_length);"
		end

	call_skipped_entity_callback (a_callback, a_user_data, a_name: POINTER; a_is_parameter: BOOLEAN)
			-- Invoke native `XML_SkippedEntityHandler'.
		require
			callback_attached: a_callback /= default_pointer
			name_attached: a_name /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, int)) $a_callback) ((void *) $a_user_data, (const char *) $a_name, $a_is_parameter ? 1 : 0);"
		end

	call_start_namespace_decl_callback (a_callback, a_user_data, a_prefix, a_uri: POINTER)
			-- Invoke native `XML_StartNamespaceDeclHandler'.
		require
			callback_attached: a_callback /= default_pointer
			uri_attached: a_uri /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, const char *)) $a_callback) ((void *) $a_user_data, (const char *) $a_prefix, (const char *) $a_uri);"
		end

	call_end_namespace_decl_callback (a_callback, a_user_data, a_prefix: POINTER)
			-- Invoke native `XML_EndNamespaceDeclHandler'.
		require
			callback_attached: a_callback /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *)) $a_callback) ((void *) $a_user_data, (const char *) $a_prefix);"
		end

	call_start_doctype_decl_callback (a_callback, a_user_data, a_name, a_system_id, a_public_id: POINTER; a_has_internal_subset: BOOLEAN)
			-- Invoke native `XML_StartDoctypeDeclHandler'.
		require
			callback_attached: a_callback /= default_pointer
			name_attached: a_name /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, const char *, const char *, int)) $a_callback) ((void *) $a_user_data, (const char *) $a_name, (const char *) $a_system_id, (const char *) $a_public_id, $a_has_internal_subset ? 1 : 0);"
		end

	call_end_doctype_decl_callback (a_callback, a_user_data: POINTER)
			-- Invoke native `XML_EndDoctypeDeclHandler'.
		require
			callback_attached: a_callback /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *)) $a_callback) ((void *) $a_user_data);"
		end

	call_not_standalone_callback (a_callback, a_user_data: POINTER): INTEGER
			-- Invoke native `XML_NotStandaloneHandler'.
		require
			callback_attached: a_callback /= default_pointer
		external
			"C inline"
		alias
			"return (EIF_INTEGER) ((int (*)(void *)) $a_callback) ((void *) $a_user_data);"
		end

	external_entity_parse_count (a_parser: POINTER): INTEGER
			-- Number of successful external child parser parses observed by native parser `a_parser'.
		external
			"C inline use %"xpact_native_private.h%""
		alias
			"return $a_parser != 0 ? (EIF_INTEGER) ((struct XML_ParserStruct *) $a_parser)->externalChildParseCount : (EIF_INTEGER) 0;"
		end

	last_external_child_direct_count (a_parser: POINTER): INTEGER
			-- Direct bytes reported by the most recent successful external child parse.
		external
			"C inline use %"xpact_native_private.h%""
		alias
			"return $a_parser != 0 ? (EIF_INTEGER) ((struct XML_ParserStruct *) $a_parser)->lastExternalChildDirectCount : (EIF_INTEGER) 0;"
		end

	last_external_child_indirect_count (a_parser: POINTER): INTEGER
			-- Indirect bytes reported by the most recent successful external child parse.
		external
			"C inline use %"xpact_native_private.h%""
		alias
			"return $a_parser != 0 ? (EIF_INTEGER) ((struct XML_ParserStruct *) $a_parser)->lastExternalChildIndirectCount : (EIF_INTEGER) 0;"
		end

	mark_next_external_entity_is_parameter (a_parser: POINTER; a_is_parameter: BOOLEAN)
			-- Tell the native bridge how the next external child parser should parse.
		external
			"C inline use %"xpact_native_private.h%""
		alias
			"if ($a_parser != 0) { ((struct XML_ParserStruct *) $a_parser)->nextExternalEntityIsParameter = $a_is_parameter ? XML_TRUE : XML_FALSE; }"
		end

	mark_next_external_entity_is_parameter_literal (a_parser: POINTER; a_is_literal: BOOLEAN)
			-- Tell the native bridge whether the next parameter child is inside an entity literal.
		external
			"C inline use %"xpact_native_private.h%""
		alias
			"if ($a_parser != 0) { ((struct XML_ParserStruct *) $a_parser)->nextExternalEntityIsParameterLiteral = $a_is_literal ? XML_TRUE : XML_FALSE; }"
		end

	native_stop_requested (a_parser: POINTER): BOOLEAN
			-- Has native parser `a_parser' received `XML_StopParser' during callback dispatch?
		external
			"C inline use %"xpact_native_private.h%""
		alias
			"return $a_parser != 0 && ((struct XML_ParserStruct *) $a_parser)->stopRequested ? EIF_TRUE : EIF_FALSE;"
		end

	native_stop_is_resumable (a_parser: POINTER): BOOLEAN
			-- Was native parser `a_parser' stopped with the resumable flag?
		external
			"C inline use %"xpact_native_private.h%""
		alias
			"return $a_parser != 0 && ((struct XML_ParserStruct *) $a_parser)->stopResumable ? EIF_TRUE : EIF_FALSE;"
		end

	set_native_active_callback_kind (a_parser: POINTER; a_kind: INTEGER)
			-- Record the native callback kind currently dispatching.
		external
			"C inline use %"xpact_native_private.h%""
		alias
			"if ($a_parser != 0) { ((struct XML_ParserStruct *) $a_parser)->activeCallbackKind = (int) $a_kind; }"
		end

	native_start_namespace_decl_callback (a_parser: POINTER): POINTER
			-- Native parser's namespace-start callback slot.
		external
			"C inline use %"xpact_native_private.h%""
		alias
			"return $a_parser != 0 ? (EIF_POINTER) ((struct XML_ParserStruct *) $a_parser)->startNamespaceDeclHandler : (EIF_POINTER) 0;"
		end

	native_end_namespace_decl_callback (a_parser: POINTER): POINTER
			-- Native parser's namespace-end callback slot.
		external
			"C inline use %"xpact_native_private.h%""
		alias
			"return $a_parser != 0 ? (EIF_POINTER) ((struct XML_ParserStruct *) $a_parser)->endNamespaceDeclHandler : (EIF_POINTER) 0;"
		end

	call_element_decl_callback (a_callback, a_user_data, a_name, a_model: POINTER)
			-- Invoke native `XML_ElementDeclHandler'.
		require
			callback_attached: a_callback /= default_pointer
			name_attached: a_name /= default_pointer
			model_attached: a_model /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, void *)) $a_callback) ((void *) $a_user_data, (const char *) $a_name, (void *) $a_model);"
		end

	call_notation_decl_callback (a_callback, a_user_data, a_name, a_base, a_system_id, a_public_id: POINTER)
			-- Invoke native `XML_NotationDeclHandler'.
		require
			callback_attached: a_callback /= default_pointer
			name_attached: a_name /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, const char *, const char *, const char *)) $a_callback) ((void *) $a_user_data, (const char *) $a_name, (const char *) $a_base, (const char *) $a_system_id, (const char *) $a_public_id);"
		end

	call_attlist_decl_callback (a_callback, a_user_data, a_element_name, a_attribute_name, a_attribute_type, a_default_value: POINTER; a_is_required: BOOLEAN)
			-- Invoke native `XML_AttlistDeclHandler'.
		require
			callback_attached: a_callback /= default_pointer
			element_name_attached: a_element_name /= default_pointer
			attribute_name_attached: a_attribute_name /= default_pointer
			attribute_type_attached: a_attribute_type /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, const char *, const char *, const char *, int)) $a_callback) ((void *) $a_user_data, (const char *) $a_element_name, (const char *) $a_attribute_name, (const char *) $a_attribute_type, (const char *) $a_default_value, $a_is_required ? 1 : 0);"
		end

	call_entity_decl_callback (a_callback, a_user_data, a_name: POINTER; a_is_parameter: BOOLEAN; a_value: POINTER; a_value_length: INTEGER; a_base, a_system_id, a_public_id, a_notation_name: POINTER)
			-- Invoke native `XML_EntityDeclHandler'.
		require
			callback_attached: a_callback /= default_pointer
			name_attached: a_name /= default_pointer
			non_negative_value_length: a_value_length >= 0
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, int, const char *, int, const char *, const char *, const char *, const char *)) $a_callback) ((void *) $a_user_data, (const char *) $a_name, $a_is_parameter ? 1 : 0, (const char *) $a_value, (int) $a_value_length, (const char *) $a_base, (const char *) $a_system_id, (const char *) $a_public_id, (const char *) $a_notation_name);"
		end

	call_unparsed_entity_decl_callback (a_callback, a_user_data, a_name, a_base, a_system_id, a_public_id, a_notation_name: POINTER)
			-- Invoke native `XML_UnparsedEntityDeclHandler'.
		require
			callback_attached: a_callback /= default_pointer
			name_attached: a_name /= default_pointer
			system_id_attached: a_system_id /= default_pointer
		external
			"C inline"
		alias
			"((void (*)(void *, const char *, const char *, const char *, const char *, const char *)) $a_callback) ((void *) $a_user_data, (const char *) $a_name, (const char *) $a_base, (const char *) $a_system_id, (const char *) $a_public_id, (const char *) $a_notation_name);"
		end

	call_external_entity_ref_callback (a_callback, a_parser, a_context, a_base, a_system_id, a_public_id: POINTER): INTEGER
			-- Invoke native `XML_ExternalEntityRefHandler'.
		require
			callback_attached: a_callback /= default_pointer
			system_id_attached: a_system_id /= default_pointer
		external
			"C inline"
		alias
			"return (EIF_INTEGER) ((int (*)(void *, const char *, const char *, const char *, const char *)) $a_callback) ((void *) $a_parser, (const char *) $a_context, (const char *) $a_base, (const char *) $a_system_id, (const char *) $a_public_id);"
		end

end
