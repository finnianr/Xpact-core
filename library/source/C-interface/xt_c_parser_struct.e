note
	description: "[
		Read/write access to selected fields in `struct XML_ParserStruct' defined in `<xpact_private.h>'.
		
		Fields related to parser state, and running totals of content bytes parsed and
		content resulting from the expansion of defined entities.

		Include File:
		 	contrib/xpact/include/xpact_private.h
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-20 11:44:00 GMT (Thursday 20th August 2026)"
	revision: "1"

class
	XT_C_PARSER_STRUCT

inherit
	EL_C_API

feature {NONE} -- Access

	frozen c_base (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->base"
		end

	frozen c_user_data (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->userData"
		end

	frozen c_unknown_encoding_handler_data (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->unknownEncodingHandlerData"
		end

	frozen c_naming_mode (ptr: POINTER): INTEGER
		-- set class `XT_NAMING_MODE_CONSTANTS'
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				XML_Parser p = (XML_Parser) $ptr;
				int result = 1; // NM_prefix_SEP_localname
				if (p->is_uri_mapped_ns){
					if (p->returnNsTriplet)
						result = 3; // NM_uri_SEP_localname_SEP_prefix
					else
						result = 2; // NM_uri_SEP_localname
				}
				return result;
			]"
		end

	frozen c_namespace_separator (ptr: POINTER): CHARACTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->namespaceSeparator"
		end

	frozen c_null_index (ptr: POINTER): INTEGER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->null_index"
		end

	frozen c_null_swap (ptr: POINTER): CHARACTER
		-- saved character that was over written by NULL character
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->null_swap"
		end

	frozen c_protocol_encoding_name (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->protocol_encoding_name"
		end

feature {NONE} -- DTD access

	frozen c_parameter_entity_parsing (ptr: POINTER): INTEGER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->dtd.paramEntityParsing"
		end

feature {NONE} -- DTD status query

	frozen c_dtd_keep_processing (ptr: POINTER): BOOLEAN
		-- false once a parameter entity reference has been skipped
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->dtd.keep_processing"
		end

	frozen c_has_parameter_entity_reference (ptr: POINTER): BOOLEAN
		-- `true' once an internal or external PE reference has been encountered
		-- this includes the reference to an external subset
		-- For example:
		-- 	<!DOCTYPE xsl:stylesheet [
		-- 		<!ENTITY % selectors SYSTEM "db-selectors.mod">
		-- 		%selectors;
		-- 	]>
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->dtd.hasParamEntityRefs"
		end

	frozen c_param_entity_parsing_enabled (ptr: POINTER): BOOLEAN
		-- possible `PE_parsing_unless_standalone' value of `paramEntityParsing' is
		-- overwritten in `read_declaration' so it becomes binary state.
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->dtd.paramEntityParsing > 0 ? 1 : 0"
		end

	frozen c_is_standalone (ptr: POINTER): BOOLEAN
		-- `True' if document is standalone
		-- standalone="yes" is the author's claim that no external markup declarations affect the document's content
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->dtd.is_standalone"
		end

feature {NONE} -- DTD element change

	frozen c_set_dtd_keep_processing (ptr: POINTER; flag: BOOLEAN)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->dtd.keep_processing = (XML_Bool)$flag;"
		ensure
			dtd_keep_processing_set: c_dtd_keep_processing (ptr) = flag
		end

	frozen c_set_has_parameter_entity_reference (ptr: POINTER; flag: BOOLEAN)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->dtd.hasParamEntityRefs = (XML_Bool)$flag;"
		ensure
			has_parameter_entity_reference_set: c_has_parameter_entity_reference (ptr) = flag
		end

	frozen c_set_parameter_entity_parsing (ptr: POINTER; status: INTEGER)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->dtd.paramEntityParsing = (enum XML_ParamEntityParsing)$status;"
		ensure
			parameter_entity_parsing_set: c_parameter_entity_parsing (ptr) = status
		end

	frozen c_set_standalone (ptr: POINTER; yes: BOOLEAN)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->dtd.is_standalone = (XML_Bool)$yes;"
		ensure
			is_standalone_set: c_is_standalone (ptr) = yes
		end

feature {NONE} -- Combined ASCII + UTF-8 upper byte classification

	frozen c_byte_type_code (ptr, character_ptr: POINTER): INTEGER
		-- byte classification for `i'th character in `character_buffer'
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->byte_type_table [(int)*((unsigned char *)$character_ptr)]"
		end

	frozen c_byte_table_item (ptr: POINTER; i: INTEGER): INTEGER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->byte_type_table [(int)$i]"
		end

feature {NONE} -- Status query

	frozen c_has_dtd_section (ptr: POINTER): BOOLEAN
		-- `True' if prolog has document type definition (DTD) after DOCTYPE x [
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->has_dtd_section"
		end

	frozen c_entity_handled (ptr: POINTER): BOOLEAN
		-- `True' if entity already handled by XML_UnparsedEntityDeclHandler
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->entity_handled"
		end

feature {NONE} -- Measurement

	frozen c_handler_call_depth (ptr: POINTER): NATURAL
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->handler_call_depth"
		end

	frozen c_size_of_parser_struct: INTEGER
			-- Size in bytes of one `XML_Parser' record
		external
			"C inline use <xpact_private.h>"
		alias
			"sizeof (struct XML_ParserStruct)"
		end

feature {NONE} -- Parsing section state

	frozen c_in_prolog_section (ptr: POINTER): BOOLEAN
		-- `True' when parsing prolog section
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->in_prolog_section"
		end

	frozen c_in_dtd_section (ptr: POINTER): BOOLEAN
		-- `True' when parsing document type definition section
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->in_dtd_section"
		end

	frozen c_in_cdata_section (ptr: POINTER): BOOLEAN
		-- `True' when outputting text in CDATA section
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->in_CDATA_section"
		end

feature {NONE} -- Parsing status change

	frozen set_has_dtd_section (ptr: POINTER; flag: BOOLEAN)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->has_dtd_section = (XML_Bool)$flag;"
		ensure
			has_dtd_section_set: c_has_dtd_section (ptr) = flag
		end

	frozen set_entity_handled (ptr: POINTER; flag: BOOLEAN)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->entity_handled = (XML_Bool)$flag;"
		ensure
			has_dtd_section_set: c_entity_handled (ptr) = flag
		end

	frozen set_in_prolog_section (ptr: POINTER; flag: BOOLEAN)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->in_prolog_section = (XML_Bool)$flag;"
		ensure
			in_prolog_section_set: c_in_prolog_section (ptr) = flag
		end

	frozen set_in_dtd_section (ptr: POINTER; flag: BOOLEAN)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->in_dtd_section = (XML_Bool)$flag;"
		ensure
			in_dtd_section_set: c_in_dtd_section (ptr) = flag
		end

	frozen set_in_cdata_section (ptr: POINTER; flag: BOOLEAN)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->in_CDATA_section = (XML_Bool)$flag;"
		ensure
			in_cdata_section_set: c_in_cdata_section (ptr) = flag
		end

feature {NONE} -- Element change

	frozen c_set_naming_mode (ptr: POINTER; naming_mode: INTEGER; separator: CHARACTER)
		-- set class `XT_NAMING_MODE_CONSTANTS'
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				XML_Parser p = (XML_Parser) $ptr;
				int naming_mode = (int)$naming_mode;

				switch (naming_mode) {
					case 2: // NM_uri_SEP_localname
					case 3: // NM_uri_SEP_localname_SEP_prefix
						p->returnNsTriplet = naming_mode == 3 ? 1 : 0;
						p->is_uri_mapped_ns = 1;
						p->namespaceSeparator =	(XML_Char)$separator;
						break;
					default: // NM_prefix_SEP_localname
						p->returnNsTriplet = 0;
						p->is_uri_mapped_ns = 0;
						p->namespaceSeparator =	'\0';
						break;
				}
			]"
		end

	frozen decrement_handler_call_depth (ptr: POINTER)
		require
			parser_attached: is_attached (ptr)
			not_zero: c_handler_call_depth (ptr) /= 0
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->handler_call_depth --;"
		end

	frozen increment_handler_call_depth (ptr: POINTER)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->handler_call_depth ++;"
		end

	frozen set_active_callback_kind (ptr: POINTER; kind: INTEGER)
		require
			parser_attached: is_attached (ptr)
			-- Record the native callback kind currently dispatching.
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->activeCallbackKind = (int) $kind;"
		end

	frozen set_handler_call_depth (ptr: POINTER; depth: NATURAL)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->handler_call_depth = (unsigned)$depth;"
		ensure
			handler_call_depth_set: c_handler_call_depth (ptr) = depth
		end

	frozen set_null_swap (ptr: POINTER; null_swap: CHARACTER)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->null_swap = (XML_Char)$null_swap;"
		ensure
			null_swap_set: null_swap = c_null_swap (ptr)
		end

	frozen set_null_index (ptr: POINTER; null_index: INTEGER)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->null_index = (int)$null_index;"
		ensure
			null_index_set: null_index = c_null_index (ptr)
		end

	frozen put_byte_table (ptr: POINTER; i, type: INTEGER)
		require
			parser_attached: is_attached (ptr)
			valid_index: 0 <= i and i < 256
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->byte_type_table [(int)$i] = (int)$type;"
		end

end
