note
	description: "[
		Allocated memory for `struct XML_ParserStruct' defined in
			
			contrib/xpact/include/xpact_private.h
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-16 09:20:00 GMT (Wednesday 16th September 2026)"
	revision: "1"

class
	XT_PARSER_DATA

inherit
	EL_ALLOCATED_C_OBJECT
		rename
			make_default as make_allocated
		end

	XT_C_PARSER_STRUCT
		rename
			c_size_of_parser_struct as c_size_of
		undefine
			copy, is_equal
		end

	XT_NAMING_MODE_CONSTANTS
		export
			{ANY} Valid_naming_modes
		undefine
			copy, is_equal
		end

	XT_PARSE_CONSTANTS
		undefine
			copy, is_equal
		end

create
	make, make_default, make_shared

feature {NONE} -- Initialization

	make_default
		do
			make (NM_prefix_SEP_localname, '%U')
		end

	make (a_naming_mode: INTEGER; separator: CHARACTER_8)
		require
			valid_naming_mode: Valid_naming_modes.has (a_naming_mode)
		do
			make_allocated
			set_naming_mode (a_naming_mode, separator)
			set_defaults
		end

feature -- Element change

	set_defaults
		do
			set_has_dtd_section (self_ptr, False)
			set_handler_call_depth (self_ptr, 0)
			set_in_prolog_section (self_ptr, True)
			set_in_cdata_section (self_ptr, False)
			set_in_dtd_section (self_ptr, False)
			c_set_accounting_source_type (self_ptr, Source_content)
			c_set_accounting_content_count (self_ptr, 1) -- prevent divide by zero error
			c_set_entity_expansion_count (self_ptr, 0)
		end

	set_naming_mode (a_naming_mode: INTEGER; separator: CHARACTER)
		do
			c_set_naming_mode (self_ptr, a_naming_mode, separator)
		ensure
			naming_mode_set: naming_mode = a_naming_mode
		end

	set_exponential_expansion_threshold (threshold_count: NATURAL_64)
		do
			c_set_exponential_expansion_threshold (self_ptr, threshold_count)
		end

	set_max_expansion_proportion (value: REAL_32)
		do
			c_set_max_expansion_proportion (self_ptr, value)
		end

feature -- Access

	naming_mode: INTEGER
		do
			Result := c_naming_mode (self_ptr)
		end

	namespace_separator: CHARACTER
		do
			Result := c_namespace_separator (self_ptr)
		end

	new_element_context: XT_ELEMENT_CONTEXT
		do
			create Result.make (self_ptr)
		end

feature -- Measurement

	handler_call_depth: NATURAL
		do
			Result := c_handler_call_depth (self_ptr)
		end

	max_expansion_proportion: DOUBLE
		do
			Result := c_max_expansion_proportion (self_ptr)
		end

	content_count: NATURAL_64
		do
			Result := c_accounting_content_count (self_ptr)
		end

feature -- Status query

	in_prolog_section: BOOLEAN
		do
			Result := c_in_prolog_section (self_ptr)
		end

	in_cdata_section: BOOLEAN
		do
			Result := c_in_cdata_section (self_ptr)
		end

end
