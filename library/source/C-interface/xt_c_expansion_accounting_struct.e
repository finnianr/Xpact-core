note
	description: "[
		Interface to C struct for entity expansion accounting

			typedef struct accounting {
			  XmlBigCount countBytesDirect;
			  XmlBigCount countBytesIndirect;
			  unsigned long debugLevel;
			  float maximumAmplificationFactor; // >=1.0
			  unsigned long long activationThresholdBytes;
			  unsigned char source_type; // See {XT_PARSE_CONSTANTS}.Source_content
			} ACCOUNTING;

	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-10-05 10:40:00 GMT (Monday 5th October 2026)"
	revision: "1"

class
	XT_C_EXPANSION_ACCOUNTING_STRUCT

inherit
	EL_C_API

feature {NONE} -- Access

	frozen c_accounting_source_type (ptr: POINTER): NATURAL_8
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.source_type"
		end

feature {NONE} -- Status query

	frozen is_entity_expansion_limit_breached (ptr: POINTER): BOOLEAN
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"[
				XML_Parser p = (XML_Parser) $ptr;
				XmlBigCount combined_count; unsigned char result = 0;

				combined_count = p->accounting.countBytesDirect + p->accounting.countBytesIndirect;
				if ((float)combined_count / p->accounting.countBytesDirect > p->accounting.maximumAmplificationFactor)
					result = 1;
				return result;
			]"
		end

feature {NONE} -- Measurement

	frozen c_accounting_content_count (ptr: POINTER): NATURAL_64
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.countBytesDirect"
		end

	frozen c_entity_expansion_count (ptr: POINTER): NATURAL_64
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.countBytesIndirect"
		end

	frozen c_exponential_expansion_threshold (ptr: POINTER): NATURAL_64
		-- number of bytes processed after which checks for runaway entity expansion
		-- should be performed
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.activationThresholdBytes"
		end

	frozen c_max_expansion_proportion (ptr: POINTER): DOUBLE
		-- maximum proportion of entity expanded text to already processed text
		-- permitted before raising error `Error_amplification_limit_breach'
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.maximumAmplificationFactor"
		end

feature {NONE} -- Element change

	frozen add_to_content_count (ptr: POINTER; value: INTEGER)
		require
			non_negative: value >= 0
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.countBytesDirect += (XmlBigCount) $value;"
		ensure
			added: c_accounting_content_count (ptr) = old c_accounting_content_count (ptr) + value.to_natural_64
		end

	frozen add_to_entity_expansion_count (ptr: POINTER; value: INTEGER)
		require
			non_negative: value >= 0
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.countBytesIndirect += (XmlBigCount) $value;"
		ensure
			added: c_entity_expansion_count (ptr) = old c_entity_expansion_count (ptr) + value.to_natural_64
		end

	frozen c_set_accounting_content_count (ptr: POINTER; value: NATURAL_64)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.countBytesDirect = (XmlBigCount)$value;"
		ensure
			content_count_set: c_accounting_content_count (ptr) = value
		end

	frozen c_set_accounting_source_type (ptr: POINTER; type: NATURAL_8)
		require
			three_types: 0 <= type and type <= 2
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.source_type = (unsigned char)$type;"
		ensure
			content_count_set: c_accounting_source_type (ptr) = type
		end

	frozen c_set_exponential_expansion_threshold (ptr: POINTER; threshold_count: NATURAL_64)
		require
			parser_attached: is_attached (ptr)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.activationThresholdBytes = (unsigned long long)$threshold_count;"
		ensure
			exponential_expansion_threshold_set: threshold_count = c_exponential_expansion_threshold (ptr)
		end

	frozen c_set_max_expansion_proportion (ptr: POINTER; value: REAL_32)
		require
			value_gt_1: value >= 1.0
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.maximumAmplificationFactor = $value;"
		ensure
			max_expansion_proportion_set: c_max_expansion_proportion (ptr) = value
		end

	frozen c_set_entity_expansion_count (ptr: POINTER; value: NATURAL_64)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Parser) $ptr)->accounting.countBytesIndirect = (XmlBigCount)$value;"
		ensure
			entity_expansion_count_set: c_entity_expansion_count (ptr) = value
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

				switch (p->accounting.source_type) {
					case 2: // Source_expansion_with_checks
						break;
					default:
						combined_count = p->accounting.countBytesDirect + p->accounting.countBytesIndirect;
						if (combined_count > p->accounting.activationThresholdBytes)
							p->accounting.source_type = 2; // Source_expansion_with_checks
						else
							p->accounting.source_type = 1; // Source_expansion;
						break;
				}
			]"
		end

end
