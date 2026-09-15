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

feature {NONE} -- Parse section state

	frozen c_has_dtd_section (ptr: POINTER): BOOLEAN
		-- True if prolog has document type definition (DTD) after DOCTYPE x [
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->has_dtd_section"
		end

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

feature {NONE} -- Measurement

	frozen c_content_count (ptr: POINTER): NATURAL_64
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

	frozen c_size_of_parser_struct: INTEGER
			-- Size in bytes of one `XML_Parser' record
		external
			"C inline use <xpact_private.h>"
		alias
			"(EIF_INTEGER_32) sizeof (struct XML_ParserStruct)"
		end

feature {NONE} -- Element change

	frozen set_active_callback_kind (ptr: POINTER; kind: INTEGER)
		require
			parser_attached: is_attached (ptr)
			-- Record the native callback kind currently dispatching.
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->activeCallbackKind = (int) $kind;"
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

feature {NONE} -- Status change

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

feature {NONE} -- Accounting initialization

-- typedef struct accounting {
-- 	XmlBigCount countBytesDirect;
-- 	XmlBigCount countBytesIndirect;
-- 	unsigned long debugLevel;
-- 	float maximumAmplificationFactor; // >=1.0
-- 	unsigned long long activationThresholdBytes;
--} ACCOUNTING;

	frozen set_content_count (ptr: POINTER; value: NATURAL_64)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.countBytesDirect = (XmlBigCount)$value;"
		ensure
			content_count_set: c_content_count (ptr) = value
		end

	frozen set_entity_expansion_count (ptr: POINTER; value: NATURAL_64)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.countBytesIndirect = (XmlBigCount)$value;"
		ensure
			entity_expansion_count_set: c_entity_expansion_count (ptr) = value
		end

	frozen set_exponential_expansion_threshold (ptr: POINTER; threshold_count: NATURAL_64)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.activationThresholdBytes = (unsigned long long)$threshold_count;"
		ensure
			exponential_expansion_threshold_set: threshold_count = c_exponential_expansion_threshold (ptr)
		end

	frozen set_max_expansion_proportion (ptr: POINTER; value: REAL_32)
		require
			value_gt_1: value >= 1.0
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.maximumAmplificationFactor = $value;"
		ensure
			max_expansion_proportion_set: c_max_expansion_proportion (ptr) = value
		end

feature {NONE} -- Accounting addition

	frozen add_to_content_count (ptr: POINTER; value: INTEGER)
		require
			non_negative: value >= 0
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->m_accounting.countBytesDirect += (XmlBigCount) $value;"
		ensure
			added: c_content_count (ptr) = old c_content_count (ptr) + value.to_natural_64
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

end
