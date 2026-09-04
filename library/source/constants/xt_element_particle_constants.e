note
	description: "[
		Content-model type and quantifier codes for ${XT_ELEMENT_PARTICLE}
		See `XML_Content_Type' and `XML_Content_Quant' enums from `expat.h'.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-02 06:05:00 GMT (Wednesday 2nd September 2026)"
	revision: "1"

class
	XT_ELEMENT_PARTICLE_CONSTANTS

feature {NONE} -- Content type codes (ordinal matches C enum XML_Content_Type)

	CT_empty: INTEGER = 1
		-- XML_CTYPE_EMPTY: element declared EMPTY.

	CT_any: INTEGER = 2
		-- XML_CTYPE_ANY: element declared ANY.

	CT_mixed: INTEGER = 3
		-- XML_CTYPE_MIXED: element declared as mixed content, e.g. (#PCDATA|a|b)*.

	CT_name: INTEGER = 4
		-- XML_CTYPE_NAME: a single child-element name (leaf particle).

	CT_choice: INTEGER = 5
		-- XML_CTYPE_CHOICE: alternatives, e.g. (a|b|c).

	CT_sequence: INTEGER = 6
		-- XML_CTYPE_SEQ: a sequence, e.g. (a,b,c).

feature {NONE} -- Content quantifier codes (ordinal matches C enum XML_Content_Quant)

	QT_none: INTEGER = 0
		-- XML_CQUANT_NONE: no quantifier, occurs exactly once.

	QT_option: INTEGER = 1
		-- XML_CQUANT_OPT: '?' quantifier, occurs zero or one times.

	QT_repetition: INTEGER = 2
		-- XML_CQUANT_REP: '*' quantifier, occurs zero or more times.

	QT_plus: INTEGER = 3
		-- XML_CQUANT_PLUS: '+' quantifier, occurs one or more times.

feature {NONE}  -- Constants

	Content_names: LIST [STRING]
		local
			s: XT_STRING_8_ROUTINES
		once
			Result := s.to_list ("empty, any, mixed, name, choice, sequence", ',')
		ensure
			valid_last: Result [CT_sequence] ~ "sequence"
		end

	Quantifier_names: LIST [STRING]
		local
			s: XT_STRING_8_ROUTINES
		once
			Result := s.to_list ("none, option, repetition, plus", ',')
		ensure
			valid_last: Result [QT_plus + 1] ~ "plus"
		end

end
