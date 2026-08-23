note
	description: "Parse prolog of XML document"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-16 13:40:00 GMT (Saturday 16th August 2026)"
	revision: "1"

deferred class
	XT_XML_PROLOG_PARSER

inherit
	XT_PARSING_BUFFERS
		redefine
			make, set_defaults, reset
		end

	XT_DOCUMENT_SCANNER
		redefine
			make, reset
		end

	XT_PARSE_EVENTS

	XT_C_PARSE_DATA_STRUCT

	XT_PARSE_CONSTANTS
		export
			{NONE} all
		end

feature {NONE} -- Initialization

	make
		do
			create attribute_value_defaults_table.make (37)
			create parse_data_memory.make (size_of_parse_data)
			create doctype_decl_stack.make_empty (2)
			create declaration_parts_list.make (10)
			create formal_public_identifier.make (40)
			create DTD_uri.make (60)
			create element_context.make (parse_data_memory.item)
			create parameter_entity_table.make (3)
			create parameter_name_cache.make
			Precursor {XT_PARSING_BUFFERS}
			Precursor {XT_DOCUMENT_SCANNER}
		ensure then
			in_prolog_section: in_prolog_section
			content_count_is_one: c_content_count (parse_data_memory.item) = 1
		end

	set_defaults
		local
			ptr: POINTER
		do
			Precursor
			has_dtd_section			:= False
			is_standalone   	 	   := False

			ptr := parse_data_memory.item
			if not ptr.is_default_pointer then
				set_in_prolog_section (ptr, True)
				set_in_cdata_section (ptr, False)
				set_in_dtd_section (ptr, False)
				set_content_count (ptr, 1) -- prevent divide by zero error
				set_entity_expansion_count (ptr, 0)
			end
		end

feature -- Status query

	is_standalone: BOOLEAN

feature {NONE} -- Token processing

	process_doctype_definition (
		buf: like buffer; index, end_index, token: INTEGER; names: like name_cache; parse_data: POINTER
		done, default_case, common_case: TYPED_POINTER [BOOLEAN]
	): INTEGER
		local
			decl_type: INTEGER; name: STRING
		do
			inspect token
				when Tok_close_bracket then
					if doctype_decl_stack.count = 1 then
						set_in_dtd_section (parse_data, False)
					else
						Result := Error_syntax; put_boolean (done, True)
					end

				when Tok_decl_open then
					decl_type := declaration_type (buf, index + 2)
					inspect decl_type
						when 0 then
							Result := Error_syntax; put_boolean (done, True)
					else
						inspect doctype_decl_stack.count when 1 then
							doctype_decl_stack.extend (decl_type)
							declaration_parts_list.wipe_out
						else
							Result := Error_syntax; put_boolean (done, True)
						end
					end

				when Tok_decl_close then
					inspect doctype_decl_stack.count when 2 then
						doctype_decl_stack.remove_tail (1)
						is_parameter_entity := False
					else
						Result := Error_syntax; put_boolean (done, True)
					end

				when Tok_name then
					inspect declaration
						when Attlist then
							if doctype_decl_stack.count = 2 then
								on_attribute_declaration_part (buf, index, end_index, token, names)
							else
								Result := Error_syntax; put_boolean (done, True)
							end

						when Entity then
							if doctype_decl_stack.count = 2 then
								if is_parameter_entity then
									on_parameter_entity_declaration_part (buf, index, end_index)
								else
									on_entity_declaration_part (buf, index, end_index)
								end
							else
								Result := Error_syntax; put_boolean (done, True)
							end
						when Element, Notation then
							do_nothing -- for now
					else
						put_boolean (default_case, True)
					end

				when Tok_literal then
					inspect declaration
						when Attlist then
							if doctype_decl_stack.count = 2 then
								on_attribute_declaration_part (buf, index + 1, end_index - 1, token, names)
							else
								Result := Error_syntax; put_boolean (done, True)
							end
						when Entity then
							if doctype_decl_stack.count = 2 then
								if is_parameter_entity then
									on_parameter_entity_declaration_part (buf, index + 1, end_index - 1)
								else
									on_entity_declaration_part (buf, index + 1, end_index - 1)
								end
							else
								Result := Error_syntax; put_boolean (done, True)
							end

						when Element, Notation then
							do_nothing -- for now
					else
						put_boolean (default_case, True)
					end

				when Tok_pound_name then
					inspect declaration
						when Attlist then
							on_attribute_declaration_part (buf, index, end_index, token, names)

						when Element, Entity, Notation then
							do_nothing -- for now
					else
						put_boolean (default_case, True)
					end
				when Tok_percent then
					is_parameter_entity := True

				when Tok_param_entity_ref then
					name := parameter_name_cache.item (buf, index + 1, end_index - 1, 0)
					if attached parameter_entity_table [name] as parameter then
						parameter.set_referenced
					end

			else
				put_boolean (common_case, True)
			end
		end

	process_prolog (
		buf: like buffer; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]; attributes: XT_ATTRIBUTE_LIST
		names: like name_cache; parse_data: POINTER; a_index: TYPED_POINTER [INTEGER]; done: TYPED_POINTER [BOOLEAN]
	): INTEGER
		-- process XML prolog from `buf' writing back changes in values to `index' and `done'
		local
			token, tok_end, decl_type, index: INTEGER; default_case, common_case: BOOLEAN
			yes_no: STRING
		do
			index := read_integer_32 (a_index)
			token := scan_prolog (buf, index, end_index, bt_table)
			tok_end := next_token_index
			if c_in_dtd_section (parse_data) then
				Result := process_doctype_definition (
					buf, index, tok_end - 1, token, names, parse_data, done, $default_case, $common_case
				)
			else
				inspect token
					when Tok_xml_decl then
						if index > 0 then
							Result := Error_misplaced_xml_pi; put_boolean (done, True)

						elseif not attributes.has_valid_encoding (buf) then
							Result := Error_unknown_encoding; put_boolean (done, True)
						else
							yes_no := attributes.standalone_value (buf)
							if Valid_yes_no.has (yes_no) then
								is_standalone := yes_no [1] = 'y'
								on_xml_declaration (buf, attributes)
								attributes.wipe_out
							else
								Result := Error_xml_decl; put_boolean (done, True)
							end
						end

					when Tok_instance_start then
						if element_context.reached_depth_zero then
							Result := Error_junk_after_doc_element; put_boolean (done, True)
						else
							set_in_prolog_section (parse_data, False)
							attributes.set_permit_undefined_entities (permit_undefined_entities)
							if not element_context.has_attributes and then attribute_value_defaults_table.count > 0 then
								create {XT_ELEMENT_ATTRIBUTES_CONTEXT} element_context.make (parse_data, attribute_value_defaults_table)
							end
						end

					when Tok_decl_open then
						decl_type := declaration_type (buf, index + 2)
						inspect decl_type
							when 0 then
								Result := Error_syntax; put_boolean (done, True)
						else
							inspect doctype_decl_stack.count when 0 then
								doctype_decl_stack.extend (decl_type)
								declaration_parts_list.wipe_out
							else
								Result := Error_syntax; put_boolean (done, True)
							end
						end

					when Tok_decl_close then
						inspect doctype_decl_stack.count when 1 then
							doctype_decl_stack.remove_tail (1)
							if has_dtd_section then
								do_nothing

							elseif not valid_doctype_declaration then
								Result := Error_syntax; put_boolean (done, True)
							else
								on_doctype_declaration_start (declaration_parts_list, False)
							end
						else
							Result := Error_syntax; put_boolean (done, True)
						end

					when Tok_literal then
						if declaration = Doctype and then doctype_decl_stack.count = 1 then
							on_document_declaration_part (buf, index, tok_end - 1)
						else
							Result := name_error (buf, index, end_index, bt_table); put_boolean (done, True)
						end

					when Tok_name then
						if declaration = Doctype and then doctype_decl_stack.count = 1 then
							on_document_declaration_part (buf, index, tok_end - 1)
						else
							Result := name_error (buf, index, end_index, bt_table); put_boolean (done, True)
						end

					when Tok_open_bracket then
						if doctype_decl_stack.count = 1 then
							if valid_doctype_declaration then
								set_in_dtd_section (parse_data, True)
								has_dtd_section := True
								on_doctype_declaration_start (declaration_parts_list, True)
							else
								Result := Error_syntax; put_boolean (done, True)
							end
						else
							Result := Error_syntax; put_boolean (done, True)
						end

				else
					common_case := True
				end
			end
			if common_case then
				inspect token
					when Tok_comment then
						on_comment (buf, index + 4, tok_end - 4, attributes)

					when Tok_invalid then
						Result := Error_invalid_token
					-- Checking for binary data masquerading as XML
						if start_index = 0 and then not is_plausible_xml (buf, start_index, end_index, bt_table)
							and then has_syntax_error (buf, start_index, end_index, bt_table)
						then
							Result := Error_syntax
						end
						put_boolean (done, True)

					when Tok_open_bracket, Tok_close_bracket, Tok_open_paren, Tok_close_paren, Tok_or, Tok_name_question then
						if doctype_decl_stack.count = 0 then
							Result := Error_syntax; put_boolean (done, True)
						end

					when Tok_pi then
						on_processing_instruction (buf, index + 2, tok_end - 3, attributes)
						attributes.wipe_out

					when Tok_prolog_whitespace then
						do_nothing

				else
					default_case := True
				end
			end
			if default_case then
				if element_context.reached_depth_zero and then not is_white_space (buf, index, end_index - 1) then
					Result := Error_junk_after_doc_element; put_boolean (done, True)

				elseif token <= 0 then
					put_boolean (done, True)  -- partial; wait for more data

				else
				-- skip prolog token					
					put_integer_32 (a_index, tok_end)
				end
			end
			if not read_boolean (done) then
				put_integer_32 (a_index, tok_end)
			end
		end

feature {NONE} -- Event handlers

	on_attribute_declaration_part (buf: like buffer; start_index, end_index, token: INTEGER; names: like name_cache)
		local
			default_values_list: ARRAYED_LIST [STRING]; colon_index: INTEGER; s8: XT_STRING_8_ROUTINES
		do
			inspect declaration_parts_list.count
				when 0, 1 then
					colon_index := s8.index_of (buf, ':', start_index, end_index)
					declaration_parts_list.extend (names.item (buf, start_index, end_index, colon_index.max (0)))

				when 2 then
					if same_characters (buf, start_index, end_index, CDATA) then
						declaration_parts_list.extend (CDATA)
					end
			else
				inspect token
					when Tok_literal then
						if declaration_parts_list.last = CDATA then
							if attached attribute_value_defaults_table [declaration_parts_list.first] as list then
								default_values_list := list
							else
								create default_values_list.make (5)
								attribute_value_defaults_table.extend (default_values_list, declaration_parts_list.first)
							end
							default_values_list.extend (declaration_parts_list [2])
							default_values_list.extend (new_attribute_value (buf, start_index, end_index, newline_or_tab_found))
						end
					when Tok_pound_name then
						declaration_parts_list.extend (name_cache.item (buf, start_index, end_index, 0))

				else
				end
			end
		end

	on_entity_declaration_part (buf: like buffer; start_index, end_index: INTEGER)
		local
			abnormal_string: XT_ABNORMAL_STRING; id: STRING
		do
			inspect declaration_parts_list.count
				when 0 then
					declaration_parts_list.extend (entity_cache.item (buf, start_index, end_index))
				when 1 then
					id := external_id (buf, start_index, end_index)
					if id /= Unknown_id then
						declaration_parts_list.extend (id)
					else
						if newline_or_tab_found then
							create abnormal_string.make (buf, start_index, end_index, newline_or_tab_found)
							entity_table.put (abnormal_string, declaration_parts_list.first)
						else
							entity_table.put (new_substring (buf, start_index, end_index), declaration_parts_list.first)
						end
					end
				when 2 then
				-- &legal; referenced near end of document /usr/share/gnome/help/synaptic/C/synaptic.xml
				-- Defined as external: <!ENTITY legal SYSTEM "gpl.xml">
				-- Without putting into table there will be a %N missing in output compared to eXpat
					entity_table.put (Empty_string, declaration_parts_list.first)
			else
			end
		end

	on_parameter_entity_declaration_part (buf: like buffer; start_index, end_index: INTEGER)
		local
			id: STRING; parameter: XT_PARAMETER_ENTITY
		do
			inspect declaration_parts_list.count
				when 0 then
					declaration_parts_list.extend (parameter_name_cache.item (buf, start_index, end_index, 0))
				when 1 then
					id := external_id (buf, start_index, end_index)
					if id /= Unknown_id then
						declaration_parts_list.extend (id)
					else
						declaration_parts_list.extend (new_substring (buf, start_index, end_index))
					end
				when 2 then
					if Valid_external_id_list.has (declaration_parts_list [2]) then
						create parameter.make (declaration_parts_list, new_substring (buf, start_index, end_index))
						parameter_entity_table.put (parameter, declaration_parts_list [1])
					end
			else
			end
		end

	on_document_declaration_part (buf: like buffer; start_index, end_index: INTEGER)
		do
			inspect declaration_parts_list.count
				when 0 then
					declaration_parts_list.extend (name_cache.item (buf, start_index, end_index, 0))
				when 1 then
					declaration_parts_list.extend (external_id (buf, start_index, end_index))
				when 2 then
					append_area (formal_public_identifier, buf, start_index + 1, end_index - 1)
					declaration_parts_list.extend (formal_public_identifier)
				when 3 then
					append_area (DTD_uri, buf, start_index + 1, end_index - 1)
					declaration_parts_list.extend (DTD_uri)
			else
			end
		end

feature {NONE} -- Implementation

	in_prolog_section: BOOLEAN
		do
			Result := c_in_prolog_section (parse_data_memory.item)
		end

	in_doctype_definition: BOOLEAN
		do
			Result := doctype_decl_stack.count > 0
		end

	declaration: INTEGER
		-- top of current DOCTYPE declaration stack
		do
			if attached doctype_decl_stack as stack then
				if stack.count > 0 then
					Result := stack [stack.count - 1]
				end
			end
		end

	declaration_type (buf: like buffer; offset: INTEGER): INTEGER
		-- one of: Attlist, Doctype, Element, Entity or 0 if no match
		do
			across Document_definition_names as name until Result > 0 loop
				if same_characters (buf, offset, offset + name.count - 1, name) then
					Result := @ name.cursor_index
				end
			end
		end

	external_id (buf: like buffer; start_index, end_index: INTEGER): STRING
		-- PUBLIC or SYSTEM id string, defaults to Unknown
		local
			i: INTEGER
		do
			Result := Unknown_id
			from i := 1 until i > Valid_external_id_list.count loop
				if same_characters (buf, start_index, end_index, Valid_external_id_list [i]) then
					Result := Valid_external_id_list [i]
					i := 3 -- break
				else
					i := i + 1
				end
			end
		end

	name_error (buf: like buffer; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
		-- try and agree with eXpat on whether invalid XML will be regarded as a syntax error or invalid token
		-- the assumption is that parser has been given some binary data masquerading as XML, for example:
		-- C:\Windows\WinSxS\amd64_microsoft-windows-deviceaccess_31bf3856ad364e35_10.0.26100.4202_none_a94ac2308a15fa4a\r\AppPrivacy.admx
		local
			token, index, tok_end, name_count: INTEGER; invalid_token: BOOLEAN
		do
			if element_context.reached_depth_zero then
				Result := Error_junk_after_doc_element

			elseif start_index = 0 then
				Result := Error_syntax
			else
				name_count := 1
			-- Find first section of invalid markup
				from index := start_index until index >= end_index or invalid_token or name_count >= 2 loop
					token := scan_prolog (buf, index, end_index, bt_table)
					inspect token
						when Tok_name then
							name_count := name_count + 1
						when Tok_invalid then
							invalid_token := True
					else
						tok_end := next_token_index
					end
					if not invalid_token then
						index := tok_end
					end
				end
				if name_count >= 2 then
					Result := Error_syntax

				elseif invalid_token then
					if has_syntax_error (buf, index, end_index, bt_table) then
						Result := Error_syntax
					else
						Result := Error_invalid_token
					end
				else
					if has_syntax_error (buf, tok_end, end_index, bt_table) then
						Result := Error_syntax
					else
						Result := Error_invalid_token
					end
				end
			end
		end

	permit_undefined_entities: BOOLEAN
		-- `True' if document is structured to allow undefined entities to be permitted by conforming parser
		-- Value is cached in `attribute_intervals.permit_undefined_entities'
		local
			parameter: XT_PARAMETER_ENTITY
		do
			if is_standalone then
				Result := False

			elseif DTD_uri.starts_with (Http) then
				Result := True

			elseif attached parameter_entity_table as table then
			-- Check if a PUBLIC or SYSTEM parameter entity was referenced in DTD
			-- For example:
			-- 	<!DOCTYPE xsl:stylesheet [
			-- 	<!ENTITY % selectors SYSTEM "db-selectors.mod">
			-- 	%selectors;
			-- 	]>

				from table.start until table.after or Result loop
					parameter := table.item_for_iteration
					if Valid_external_id_list.has (parameter.external_id) then
						Result := parameter.is_referenced
					end
					table.forth
				end
			end
		end

	reset
		do
			Precursor {XT_PARSING_BUFFERS}
			Precursor {XT_DOCUMENT_SCANNER}

			attribute_value_defaults_table.wipe_out
			if element_context.has_default_values then
				create element_context.make (parse_data_memory.item)
			else
				element_context.reset
			end
			parameter_entity_table.wipe_out
			parameter_name_cache.reset
			declaration_parts_list.wipe_out
			DTD_uri.wipe_out
			formal_public_identifier.wipe_out
		end

	valid_doctype_declaration: BOOLEAN
		do
			inspect declaration_parts_list.count
				when 0 then
					Result := False

				when 1 then
					Result := not Valid_external_id_list.has (declaration_parts_list [1])

				when 2, 3, 4 then
					if Valid_external_id_list.has (declaration_parts_list [2]) then
						if declaration_parts_list [2] = PUBLIC then
							Result := declaration_parts_list.count = 4

						elseif declaration_parts_list [2] = SYSTEM then
							Result := declaration_parts_list.count = 3
						end
					else
						Result := False
					end
			else
				Result := False
			end
		end

feature {NONE} -- Internal attributes

	attribute_value_defaults_table: HASH_TABLE [ARRAYED_LIST [STRING], STRING]

	declaration_parts_list: ARRAYED_LIST [STRING]
		-- For example <!ATTLIST magic priority CDATA "50">
		-- would be: << "magic", "priority", "CDATA", "50" >>

	DTD_uri: STRING
		-- DOCTYPE eg.: http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd

	doctype_decl_stack: SPECIAL [INTEGER]
		-- DOCTYPE declaration type stack

	element_context: XT_ELEMENT_CONTEXT

	formal_public_identifier: STRING
		-- Eg. from DOCTYPE "-//W3C//DTD XHTML 1.0 Transitional//EN"


	is_parameter_entity: BOOLEAN

	has_dtd_section: BOOLEAN
		-- True if prolog has document type definition (DTD) after DOCTYPE x [

	parameter_name_cache: XT_NAME_CACHE
		-- efficient lookup of parameter entity names

	parameter_entity_table: HASH_TABLE [XT_PARAMETER_ENTITY, STRING]

	parse_data_memory: MANAGED_POINTER
		-- allocated memory for C struct `XT_C_PARSE_DATA_STRUCT'

end
