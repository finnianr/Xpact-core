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

feature {NONE} -- Declaration token stack

	frozen declaration_stack_count (ptr: POINTER): INTEGER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->declaration_stack_count"
		end

	frozen declaration_stack_first (ptr: POINTER): INTEGER
		require
			parser_attached: is_attached (ptr)
			has_at_least_one_item: declaration_stack_count (ptr) >= 1
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				XML_Parser p = (XML_Parser) $ptr;
				return p->declaration_stack [0];
			]"
		end

	frozen declaration_stack_item (ptr: POINTER): INTEGER
		require
			parser_attached: is_attached (ptr)
			has_at_least_one_item: declaration_stack_count (ptr) >= 1
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				XML_Parser p = (XML_Parser) $ptr;
				return p->declaration_stack [p->declaration_stack_count - 1];
			]"
		end

	frozen declaration_stack_pop (ptr: POINTER)
		require
			parser_attached: is_attached (ptr)
			has_at_least_one_item: declaration_stack_count (ptr) >= 1
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->declaration_stack_count --;"
		end

	frozen declaration_stack_push (ptr: POINTER; item: INTEGER)
		require
			parser_attached: is_attached (ptr)
			enough_room: 2 - declaration_stack_count (ptr) > 0
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				XML_Parser p = (XML_Parser) $ptr;
				p->declaration_stack_count ++;
				p->declaration_stack [p->declaration_stack_count - 1] = (int)$item;
			]"
		end

	frozen declaration_stack_replace (ptr: POINTER; item: INTEGER)
		-- replace top item
		require
			parser_attached: is_attached (ptr)
			not_empty: declaration_stack_count (ptr) > 0
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				XML_Parser p = (XML_Parser) $ptr;
				p->declaration_stack [p->declaration_stack_count - 1] = (int)$item;
			]"
		end

	frozen declaration_stack_wipe_out (ptr: POINTER)
		require
			parser_attached: is_attached (ptr)
			has_at_least_one_item: declaration_stack_count (ptr) >= 1
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->declaration_stack_count = 0;"
		end

feature {NONE} -- Status query

	frozen c_has_dtd_section (ptr: POINTER): BOOLEAN
		-- True if prolog has document type definition (DTD) after DOCTYPE x [
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->has_dtd_section"
		end

	frozen is_entity_expansion_limit_breached (ptr: POINTER): BOOLEAN
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				XML_Parser p = (XML_Parser) $ptr;
				XmlBigCount combined_count; unsigned char result = 0;

				combined_count = p->m_accounting.countBytesDirect + p->m_accounting.countBytesIndirect;
				if ((float)combined_count / p->m_accounting.countBytesDirect > p->m_accounting.maximumAmplificationFactor)
					result = 1;
				return result;
			]"
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
			"(EIF_INTEGER_32) sizeof (struct XML_ParserStruct)"
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

feature {NONE} -- Parsing section (set)

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

feature {NONE} -- Entity expansion accounting

-- typedef struct accounting {
-- 	XmlBigCount countBytesDirect;
-- 	XmlBigCount countBytesIndirect;
-- 	unsigned long debugLevel;
-- 	float maximumAmplificationFactor; // >=1.0
-- 	unsigned long long activationThresholdBytes;
--} ACCOUNTING;

	frozen c_accounting_source_type (ptr: POINTER): NATURAL_8
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.source_type"
		end

	frozen c_accounting_content_count (ptr: POINTER): NATURAL_64
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.countBytesDirect"
		end

	frozen c_entity_expansion_count (ptr: POINTER): NATURAL_64
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.countBytesIndirect"
		end

	frozen c_exponential_expansion_threshold (ptr: POINTER): NATURAL_64
		-- number of bytes processed after which checks for runaway entity expansion
		-- should be performed
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.activationThresholdBytes"
		end

	frozen c_max_expansion_proportion (ptr: POINTER): DOUBLE
		-- maximum proportion of entity expanded text to already processed text
		-- permitted before raising error `Error_amplification_limit_breach'
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.maximumAmplificationFactor"
		end

feature {NONE} -- Entity expansion accounting (change)

	frozen add_to_content_count (ptr: POINTER; value: INTEGER)
		require
			non_negative: value >= 0
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.countBytesDirect += (XmlBigCount) $value;"
		ensure
			added: c_accounting_content_count (ptr) = old c_accounting_content_count (ptr) + value.to_natural_64
		end

	frozen add_to_entity_expansion_count (ptr: POINTER; value: INTEGER)
		require
			non_negative: value >= 0
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.countBytesIndirect += (XmlBigCount) $value;"
		ensure
			added: c_entity_expansion_count (ptr) = old c_entity_expansion_count (ptr) + value.to_natural_64
		end

	frozen update_accounting_source_type (ptr: POINTER)
		-- if total bytes of content plus total bytes of expanded entities is greater than
		-- `c_exponential_expansion_threshold (ptr)' then set source type to `Source_expansion_with_checks'
		-- but do nothing if `c_source_type (ptr) = Source_expansion_with_checks'
		-- (Constants defined in `XT_PARSE_CONSTANTS')
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				XML_Parser p = (XML_Parser) $ptr;
				XmlBigCount combined_count;

				switch (p->m_accounting.source_type) {
					case 2: // Source_expansion_with_checks
						break;
					default:
						combined_count = p->m_accounting.countBytesDirect + p->m_accounting.countBytesIndirect;
						if (combined_count > p->m_accounting.activationThresholdBytes)
							p->m_accounting.source_type = 2; // Source_expansion_with_checks
						else
							p->m_accounting.source_type = 1; // Source_expansion;
						break;
				}
			]"
		end

	frozen c_set_accounting_content_count (ptr: POINTER; value: NATURAL_64)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.countBytesDirect = (XmlBigCount)$value;"
		ensure
			content_count_set: c_accounting_content_count (ptr) = value
		end

	frozen c_set_accounting_source_type (ptr: POINTER; type: NATURAL_8)
		require
			three_types: 0 <= type and type <= 2
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.source_type = (unsigned char)$type;"
		ensure
			content_count_set: c_accounting_source_type (ptr) = type
		end

	frozen c_set_exponential_expansion_threshold (ptr: POINTER; threshold_count: NATURAL_64)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.activationThresholdBytes = (unsigned long long)$threshold_count;"
		ensure
			exponential_expansion_threshold_set: threshold_count = c_exponential_expansion_threshold (ptr)
		end

	frozen c_set_max_expansion_proportion (ptr: POINTER; value: REAL_32)
		require
			value_gt_1: value >= 1.0
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.maximumAmplificationFactor = $value;"
		ensure
			max_expansion_proportion_set: c_max_expansion_proportion (ptr) = value
		end

	frozen c_set_entity_expansion_count (ptr: POINTER; value: NATURAL_64)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.countBytesIndirect = (XmlBigCount)$value;"
		ensure
			entity_expansion_count_set: c_entity_expansion_count (ptr) = value
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

end
