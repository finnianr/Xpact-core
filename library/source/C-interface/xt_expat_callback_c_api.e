note
	description: "C callbacks defined in `<xpact_native_private.h>'"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-09 15:37:00 GMT (Wednesday 9th September 2026)"
	revision: "1"

class
	XT_EXPAT_CALLBACK_C_API

inherit
	EL_C_API

feature {NONE} -- C call backs

	frozen call_on_cdata_section_start (callback, user_data: POINTER)
		require
			callback_attached: is_attached (callback)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_StartCdataSectionHandler) $callback) ((void *) $user_data);"
		end

	frozen call_on_cdata_section_end (callback, user_data: POINTER)
		require
			callback_attached: is_attached (callback)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_EndCdataSectionHandler) $callback) ((void *) $user_data);"
		end

	frozen call_on_content (callback, user_data, text: POINTER; length: INTEGER)
			-- Invoke native `XML_CharacterDataHandler'.
		require
			callback_attached: is_attached (callback)
			text_attached: is_attached (text)
			non_negative_length: length >= 0
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_CharacterDataHandler) $callback) ((void *) $user_data, (const char *) $text, (int) $length);"
		end

	frozen call_on_comment (callback, user_data, text: POINTER)
			-- Invoke native `XML_CommentHandler'.
		require
			callback_attached: is_attached (callback)
			text_attached: is_attached (text)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_CommentHandler) $callback) ((void *) $user_data, (const char *) $text);"
		end

	frozen call_on_element_end (callback, user_data, name: POINTER)
			-- Invoke native `XML_EndElementHandler'.
		require
			callback_attached: is_attached (callback)
			name_attached: is_attached (name)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_EndElementHandler) $callback) ((void *) $user_data, (const char *) $name);"
		end

	frozen call_on_element_start (callback, user_data, name, attributes: POINTER)
			-- Invoke native `XML_StartElementHandler'.
		require
			callback_attached: is_attached (callback)
			name_attached: is_attached (name)
			attributes_attached: is_attached (attributes)
		external
			"C inline use <xpact_native_private.h>"
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
			"C inline use <xpact_native_private.h>"
		alias
			"[
				((XML_ProcessingInstructionHandler) $callback)(
					(void *) $user_data, (const char *) $target, (const char *) $data
				);
			]"
		end

	frozen call_on_xml_declaration (callback, user_data, version, encoding: POINTER; standalone: INTEGER)
			-- Invoke native `XML_XmlDeclHandler'.
		require
			callback_attached: is_attached (callback)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"[
				((XML_XmlDeclHandler) $callback)(
					(void *) $user_data, (const char *) $version, (const char *) $encoding, (int) $standalone
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
			"C inline use <xpact_native_private.h>"
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
			"C inline use <xpact_native_private.h>"
		alias
			"[
				((XML_ElementDeclHandler) $callback)(
					(void *) $user_data, (const char *) $name, (XML_Content *) $model
				);
			]"
		end

	frozen call_on_notation_declaration (callback, user_data, notation_name, base, system_id, public_id: POINTER)
			-- Invoke native `XML_NotationDeclHandler'.
		require
			callback_attached: is_attached (callback)
			notation_name_attached: is_attached (notation_name)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"[
				((XML_NotationDeclHandler) $callback)(
					(void *) $user_data, (const char *) $notation_name, (const char *) $base,
					(const char *) $system_id, (const char *) $public_id
				);
			]"
		end

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
			"C inline use <xpact_native_private.h>"
		alias
			"[
				((XML_AttlistDeclHandler) $callback)(
					(void *) $user_data, (const char *) $element_name, (const char *) $attribute_name,
					(const char *) $attribute_type, (const char *) $default_value, (int) $is_required
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
			"C inline use <xpact_native_private.h>"
		alias
			"[
				((XML_EntityDeclHandler) $callback)(
					(void *) $user_data, (const char *) $entity_name, (int) $is_parameter_entity,
					(const char *) $value, (int) $value_length, (const char *) $base,
					(const char *) $system_id, (const char *) $public_id, (const char *) $notation_name
				);
			]"
		end

end
