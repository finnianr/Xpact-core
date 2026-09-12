note
	description: "[
		External read/write access to the C `struct XML_cp' in `<xpact_private.h>'

		Include File:
		 	contrib/xpact/include/xpact_private.h
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-03 10:10:00 GMT (Thursday 3rd September 2026)"
	revision: "1"

class
	XT_ELEMENT_PARTICLE_C_API

inherit
	EL_C_API

feature {NONE} -- C struct field access

	frozen c_type (a_ptr: POINTER): INTEGER
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Content *) $a_ptr)->type"
		end

	frozen c_quantifier (a_ptr: POINTER): INTEGER
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Content *) $a_ptr)->quant"
		end

	frozen c_name (a_ptr: POINTER): POINTER
		external
			"C inline use <xpact_private.h>"
		alias
			"(EIF_POINTER) ((XML_Content *) $a_ptr)->name"
		end

	frozen c_particle_list (a_ptr: POINTER): POINTER
		external
			"C inline use <xpact_private.h>"
		alias
			"(EIF_POINTER) ((XML_Content *) $a_ptr)->children"
		end

feature {NONE} -- C struct measurement

	frozen c_size_of: INTEGER
			-- <Precursor>
		external
			"C inline use <xpact_private.h>"
		alias
			"(EIF_INTEGER_32) sizeof (XML_Content)"
		end

	frozen c_list_count (a_ptr: POINTER): NATURAL
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Content *) $a_ptr)->numchildren"
		end

feature {NONE} -- C struct field change

	frozen c_set_name (a_ptr: POINTER; a_value: POINTER)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Content *) $a_ptr)->name = (EIF_CHARACTER *) $a_value;"
		end

	frozen c_set_particle_list (a_ptr: POINTER; a_value: POINTER)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Content *) $a_ptr)->children = (XML_Content *) $a_value;"
		end

	frozen c_set_particle_list_count (a_ptr: POINTER; a_value: NATURAL)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Content *) $a_ptr)->numchildren = $a_value;"
		end

	frozen c_set_quantifier (a_ptr: POINTER; a_value: INTEGER)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Content *) $a_ptr)->quant = $a_value;"
		end

	frozen c_set_type (a_ptr: POINTER; a_value: INTEGER)
		external
			"C inline use <xpact_private.h>"
		alias
			"((XML_Content *) $a_ptr)->type = $a_value;"
		end

end
