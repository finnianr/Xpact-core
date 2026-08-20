note
	description: "[
		External read/write access to the C structure `XT_parse_data' in `<xt_structs.h>'
		
		Defined:
			C-source/xt_structs.h
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-20 11:44:00 GMT (Thursday 20th August 2026)"
	revision: "1"

class
	XT_C_PARSE_DATA_STRUCT

feature {NONE} -- Measurement

	frozen size_of_parse_data: INTEGER
			-- Size in bytes of one `XT_parse_data' record
		external
			"C inline use <xt_structs.h>"
		alias
			"return (EIF_INTEGER_32) sizeof (XT_parse_data);"
		end

feature {NONE} -- Access

	frozen c_in_prolog_section (data_ptr: POINTER): BOOLEAN
		external
			"C inline use <xt_structs.h>"
		alias
			"return ((XT_parse_data*) $data_ptr)->in_prolog_section;"
		end

	frozen c_in_dtd_section (data_ptr: POINTER): BOOLEAN
		external
			"C inline use <xt_structs.h>"
		alias
			"return ((XT_parse_data*) $data_ptr)->in_dtd_section;"
		end

	frozen c_in_cdata_section (data_ptr: POINTER): BOOLEAN
		external
			"C inline use <xt_structs.h>"
		alias
			"return ((XT_parse_data*) $data_ptr)->in_CDATA_section;"
		end

	frozen c_content_count (data_ptr: POINTER): NATURAL_64
		external
			"C inline use <xt_structs.h>"
		alias
			"return ((XT_parse_data*) $data_ptr)->content_count;"
		end

	frozen c_entity_expansion_count (data_ptr: POINTER): NATURAL_64
		external
			"C inline use <xt_structs.h>"
		alias
			"return ((XT_parse_data*) $data_ptr)->entity_expansion_count;"
		end

feature {NONE} -- Element change

	frozen set_in_prolog_section (data_ptr: POINTER; flag: BOOLEAN)
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_parse_data*) $data_ptr)->in_prolog_section = $flag;"
		end

	frozen set_in_dtd_section (data_ptr: POINTER; flag: BOOLEAN)
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_parse_data*) $data_ptr)->in_dtd_section = $flag;"
		end

	frozen set_in_cdata_section (data_ptr: POINTER; flag: BOOLEAN)
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_parse_data*) $data_ptr)->in_CDATA_section = $flag;"
		end

	frozen set_content_count (data_ptr: POINTER; value: NATURAL_64)
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_parse_data*) $data_ptr)->content_count = $value;"
		end

	frozen set_entity_expansion_count (data_ptr: POINTER; value: NATURAL_64)
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_parse_data*) $data_ptr)->entity_expansion_count = $value;"
		end

feature {NONE} -- Addition operations

	add_to_content_count (data_ptr: POINTER; value: INTEGER)
		require
			non_negative: value >= 0
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_parse_data*) $data_ptr)->content_count += (EIF_NATURAL_64) $value;"
		ensure
			added: c_content_count (data_ptr) = old c_content_count (data_ptr) + value.to_natural_64
		end

	add_to_entity_expansion_count (data_ptr: POINTER; value: INTEGER)
		require
			non_negative: value >= 0
		external
			"C inline use <xt_structs.h>"
		alias
			"((XT_parse_data*) $data_ptr)->entity_expansion_count += (EIF_NATURAL_64) $value;"
		ensure
			added: c_entity_expansion_count (data_ptr) = old c_entity_expansion_count (data_ptr) + value.to_natural_64
		end

end
