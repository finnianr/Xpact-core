note
	description: "[
		External read/write access to the C structure `XT_particle' in `<xt_structs.h>'

		Defined:
			C-source/xt_structs.h
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
			"C inline use <xt_structs.h>"
		alias
			"return ((XT_element_particle *) $a_ptr)->type;"
		end

	frozen c_set_type (a_ptr: POINTER; a_value: INTEGER)
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_element_particle *) $a_ptr)->type = $a_value;"
		end

	frozen c_quantity (a_ptr: POINTER): INTEGER
		external
			"C inline use <xt_structs.h>"
		alias
			"return ((XT_element_particle *) $a_ptr)->quantity;"
		end

	frozen c_set_quantity (a_ptr: POINTER; a_value: INTEGER)
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_element_particle *) $a_ptr)->quantity = $a_value;"
		end

	frozen c_name (a_ptr: POINTER): POINTER
		external
			"C inline use <xt_structs.h>"
		alias
			"return (EIF_POINTER) ((XT_element_particle *) $a_ptr)->name;"
		end

	frozen c_set_name (a_ptr: POINTER; a_value: POINTER)
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_element_particle *) $a_ptr)->name = (EIF_CHARACTER *) $a_value;"
		end

	frozen c_size_of: INTEGER
			-- <Precursor>
		external
			"C inline use <xt_structs.h>"
		alias
			"return (EIF_INTEGER_32) sizeof (XT_element_particle);"
		end

	frozen c_list_count (a_ptr: POINTER): NATURAL
		external
			"C inline use <xt_structs.h>"
		alias
			"return ((XT_element_particle *) $a_ptr)->list_count;"
		end

	frozen c_set_particle_list_count (a_ptr: POINTER; a_value: NATURAL)
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_element_particle *) $a_ptr)->list_count = $a_value;"
		end

	frozen c_particle_list (a_ptr: POINTER): POINTER
		external
			"C inline use <xt_structs.h>"
		alias
			"return (EIF_POINTER) ((XT_element_particle *) $a_ptr)->particle_list;"
		end

	frozen c_set_particle_list (a_ptr: POINTER; a_value: POINTER)
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_element_particle *) $a_ptr)->particle_list = (XT_element_particle *) $a_value;"
		end

end
