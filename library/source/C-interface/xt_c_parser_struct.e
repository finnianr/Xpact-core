note
	description: "[
		Parser state, callback handler functions and running totals of content bytes parsed and content resulting
		from the expansion of defined entities.
	]"
	notes: "[
		External read/write access to the C structure `XML_Parser' in `<xpact_native_private.h>'
		
		Defined:
			contrib/xpact/native/xpact_native_private.h
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

feature {NONE} -- Parse event callbacks

	frozen c_on_cdata_section_start (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->startCdataSectionHandler"
		end

	frozen c_on_cdata_section_end (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->endCdataSectionHandler"
		end

	frozen c_on_content (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->characterDataHandler"
		end

	frozen c_on_comment (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->commentHandler"
		end

	frozen c_on_element_start (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->startElementHandler"
		end

	frozen c_on_element_end (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->endElementHandler"
		end

	frozen c_on_processing_instruction (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->processingInstructionHandler"
		end

	frozen c_on_xml_declaration (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->xmlDeclHandler"
		end

	frozen c_on_doctype_declaration_start (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->startDoctypeDeclHandler"
		end

	frozen c_on_element_declaration (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->elementDeclHandler"
		end

	frozen c_on_notation_declaration (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->notationDeclHandler"
		end

	frozen c_on_attribute_list_declaration (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->attlistDeclHandler"
		end

	frozen c_on_entity_declaration (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->entityDeclHandler"
		end

feature {NONE} -- Parse section state

	frozen c_has_dtd_section (ptr: POINTER): BOOLEAN
		-- True if prolog has document type definition (DTD) after DOCTYPE x [
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->has_dtd_section"
		end

	frozen c_in_prolog_section (ptr: POINTER): BOOLEAN
		-- `True' when parsing prolog section
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->in_prolog_section"
		end

	frozen c_in_dtd_section (ptr: POINTER): BOOLEAN
		-- `True' when parsing document type definition section
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->in_dtd_section"
		end

	frozen c_in_cdata_section (ptr: POINTER): BOOLEAN
		-- `True' when outputting text in CDATA section
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->in_CDATA_section"
		end

feature {NONE} -- Status query

	frozen c_has_max_expansion_proportion (ptr: POINTER): BOOLEAN
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->hasBillionLaughsMaximumAmplification"
		end

	frozen c_has_exponential_expansion_threshold (ptr: POINTER): BOOLEAN
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->hasBillionLaughsActivationThreshold"
		end

feature {NONE} -- Member access

	frozen c_user_data (ptr: POINTER): POINTER
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->userData"
		end

feature {NONE} -- Measurement

	frozen c_content_count (ptr: POINTER): NATURAL_64
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->lastExternalChildDirectCount"
		end

	frozen c_entity_expansion_count (ptr: POINTER): NATURAL_64
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->lastExternalChildIndirectCount"
		end

	frozen c_max_expansion_proportion (ptr: POINTER): DOUBLE
		-- maximum proportion of entity expanded text to already processed text
		-- permitted before raising error `Error_amplification_limit_breach'
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->billionLaughsMaximumAmplification"
		end

	frozen c_exponential_expansion_threshold (ptr: POINTER): NATURAL_64
		-- number of bytes processed after which checks for runaway entity expansion
		-- should be performed
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->billionLaughsActivationThresholdBytes"
		end

	frozen size_of_parse_data: INTEGER
			-- Size in bytes of one `XML_Parser' record
		external
			"C inline use <xpact_native_private.h>"
		alias
			"(EIF_INTEGER_32) sizeof (struct XML_ParserStruct)"
		end

feature {NONE} -- Element change

	frozen set_exponential_expansion_threshold (ptr: POINTER; threshold_count: NATURAL_64)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->billionLaughsActivationThresholdBytes = (unsigned long long)$threshold_count;"
		end

	frozen set_active_callback_kind (ptr: POINTER; kind: INTEGER)
		require
			parser_attached: is_attached (ptr)
			-- Record the native callback kind currently dispatching.
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->activeCallbackKind = (int) $kind;"
		end

feature {NONE} -- Status change

	frozen set_has_dtd_section (ptr: POINTER; flag: BOOLEAN)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->has_dtd_section = (XML_Bool)$flag;"
		ensure
			has_dtd_section_set: c_has_dtd_section (ptr) = flag
		end

	frozen set_in_prolog_section (ptr: POINTER; flag: BOOLEAN)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->in_prolog_section = (XML_Bool)$flag;"
		ensure
			in_prolog_section_set: c_in_prolog_section (ptr) = flag
		end

	frozen set_in_dtd_section (ptr: POINTER; flag: BOOLEAN)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->in_dtd_section = (XML_Bool)$flag;"
		ensure
			in_dtd_section_set: c_in_dtd_section (ptr) = flag
		end

	frozen set_in_cdata_section (ptr: POINTER; flag: BOOLEAN)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->in_CDATA_section = (XML_Bool)$flag;"
		ensure
			in_cdata_section_set: c_in_cdata_section (ptr) = flag
		end

feature {NONE} -- Initialization

	frozen set_content_count (ptr: POINTER; value: NATURAL_64)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->lastExternalChildDirectCount = (unsigned long long)$value;"
		ensure
			content_count_set: c_content_count (ptr) = value
		end

	frozen set_entity_expansion_count (ptr: POINTER; value: NATURAL_64)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->lastExternalChildIndirectCount = (unsigned long long)$value;"
		ensure
			entity_expansion_count_set: c_entity_expansion_count (ptr) = value
		end

	frozen set_max_expansion_proportion (ptr: POINTER; value: REAL_32)
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->billionLaughsMaximumAmplification = $value;"
		ensure
			max_expansion_proportion_set: c_max_expansion_proportion (ptr) = value
		end

feature {NONE} -- Addition operations

	frozen add_to_content_count (ptr: POINTER; value: INTEGER)
		require
			non_negative: value >= 0
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->lastExternalChildDirectCount += (unsigned long long) $value;"
		ensure
			added: c_content_count (ptr) = old c_content_count (ptr) + value.to_natural_64
		end

	frozen add_to_entity_expansion_count (ptr: POINTER; value: INTEGER)
		require
			non_negative: value >= 0
		external
			"C inline use <xpact_native_private.h>"
		alias
			"((XML_Parser) $ptr)->lastExternalChildIndirectCount += (unsigned long long) $value;"
		ensure
			added: c_entity_expansion_count (ptr) = old c_entity_expansion_count (ptr) + value.to_natural_64
		end

end
