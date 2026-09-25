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
		rename
			make as make_buffers
		redefine
			set_defaults, reset
		end

	XT_DOCUMENT_SCANNER
		rename
			make as make_scanner
		redefine
			reset
		end

	XT_PARSE_EVENTS

	XT_PARSE_CONSTANTS
		rename
			ENTITY as ENTITY_,
			NOTATION as NOTATION_
		end

feature {NONE} -- Initialization

	make (a_parser_data: XT_PARSER_DATA)
		require
			valid_parse_data_size: a_parser_data.count = c_size_of_parser_struct
		do
			parser_data := a_parser_data
			create attribute_value_defaults_table.make (37)
			create doctype_declaration_stack.make_empty (2)
			doctype_identifiers := [Empty_string, Empty_string]
			element_context := parser_data.new_element_context
			create parameter_entity_table.make (3)
			create parameter_name_cache.make

			make_buffers; make_scanner (a_parser_data)

			inspect a_parser_data.naming_mode when NM_prefix_SEP_localname then
				doctype_name_cache := name_cache
			else
				create doctype_name_cache.make
			end

			create attribute_parts_list.make (doctype_name_cache)
			create document_type_parts_list.make (doctype_name_cache)
			create element_parts_list.make (doctype_name_cache)
			create entity_parts_list.make (entity_cache)
			create notation_parts_list.make (doctype_name_cache)
			create parameter_entity_parts_list.make (parameter_name_cache)

			create declaration_parts.make_filled (document_type_parts_list, PARAMETER_ENTITY)
			declaration_parts [ATTLIST - 1] := attribute_parts_list
			declaration_parts [ELEMENT - 1] := element_parts_list
			declaration_parts [ENTITY_ - 1] := entity_parts_list
			declaration_parts [NOTATION_ - 1] := notation_parts_list
			declaration_parts [PARAMETER_ENTITY - 1] := parameter_entity_parts_list

		ensure then
			in_prolog_section: in_prolog_section
			content_count_is_one: parser_data.content_count = 1
		end

	set_defaults
		do
			Precursor
			is_standalone := False
			parser_data.set_defaults
			parser_data.set_exponential_expansion_threshold (Default_exponential_expansion_threshold)
		end

feature -- Status query

	is_standalone: BOOLEAN

feature {NONE} -- Token processing

	process_doctype_definition (
		buf: like buffer; index, end_index, token: INTEGER; names: like name_cache; declaration_stack: SPECIAL [INTEGER]
		parse_data: POINTER; done, default_case, common_case: TYPED_POINTER [BOOLEAN]
	): INTEGER
		local
			decl_type, declaration: INTEGER; parts_list: XT_DECLARATION_PARTS_LIST
		do
			inspect declaration_stack.count when 0 then
				parts_list := document_type_parts_list
			else
				declaration := declaration_stack [declaration_stack.count - 1]
				parts_list := declaration_parts [declaration - 1]
			end
			inspect token
				when Tok_close_bracket then
					inspect declaration_stack.count when 1 then
						set_in_dtd_section (parse_data, False)
					else
						Result := Error_syntax; put_boolean (done, True)
					end

				when Tok_decl_open then
					decl_type := declaration_type (buf, index + 2)
					inspect decl_type when 0 then
						Result := Error_syntax; put_boolean (done, True)
					else
						inspect declaration_stack.count when 1 then
							declaration_stack.extend (decl_type)
						else
							Result := Error_syntax; put_boolean (done, True)
						end
					end

				when Tok_decl_close then
					inspect declaration_stack.count when 2 then
						Result := on_close_declaration (declaration, token, parse_data)
						declaration_stack.remove_tail (1)
					else
						Result := Error_syntax; put_boolean (done, True)
					end

				when Tok_name then
					inspect declaration when ATTLIST, ELEMENT, ENTITY_, NOTATION_, PARAMETER_ENTITY then
						if declaration_stack.count = 2 then
							parts_list.extend (buf, index, end_index, token, newline_or_tab_found)
							if parts_list.is_complete then
								Result := on_close_declaration (declaration, token, parse_data)
							end
						else
							Result := Error_syntax; put_boolean (done, True)
						end
					else
						put_boolean (default_case, True)
					end

				when Tok_name_question, Tok_name_asterisk, Tok_name_plus then
					inspect declaration when ELEMENT then
						if declaration_stack.count = 2 then
							parts_list.extend (buf, index, end_index - 1, token, newline_or_tab_found)
						else
							Result := Error_syntax; put_boolean (done, True)
						end
					else
						put_boolean (default_case, True)
					end

				when Tok_literal then
					inspect declaration when ATTLIST, ELEMENT, ENTITY_, NOTATION_, PARAMETER_ENTITY then
						if declaration_stack.count = 2 then
							if attached expanded_dtd_literal (buf, index, end_index) as str
								and then attached str.area as area
							then
								parts_list.extend (area, 0, str.count - 1, token, newline_or_tab_found)
								if parts_list.is_complete then
									Result := on_close_declaration (declaration, token, parse_data)
								end
							else
								parts_list.extend (buf, index + 1, end_index - 1, token, newline_or_tab_found)
								if parts_list.is_complete then
									Result := on_close_declaration (declaration, token, parse_data)
								end
							end
						else
							Result := Error_syntax; put_boolean (done, True)
						end
					else
						put_boolean (default_case, True)
					end

				when Tok_pound_name then
					inspect declaration
						when ATTLIST, ELEMENT, ENTITY_, NOTATION_, PARAMETER_ENTITY then
							parts_list.extend (buf, index, end_index, token, newline_or_tab_found)
							if parts_list.is_complete then
								Result := on_close_declaration (declaration, token, parse_data)
							end

					else
						put_boolean (default_case, True)
					end

				when Tok_percent then
					inspect declaration when ENTITY_ then
						inspect declaration_stack.count when 2 then
							declaration := PARAMETER_ENTITY
							declaration_stack [1] := declaration
						else end
					else end

				when Tok_param_entity_ref then
					Result := process_parameter_entity (
						buf, index + 1, end_index - 1, names, declaration_stack, parse_data, done
					)

				when Tok_open_parenthesis, Tok_or, Tok_close_parenthesis, Tok_close_paren_plus,
					Tok_close_paren_question, Tok_close_paren_asterisk, Tok_comma
				then
					parts_list.on_operator (token)

			else
				put_boolean (common_case, True)
			end
		end

	process_parameter_entity (
		buf: like buffer; start_index, end_index: INTEGER; names: like name_cache; declaration_stack: SPECIAL [INTEGER]
		parse_data: POINTER; done: TYPED_POINTER [BOOLEAN]
	): INTEGER
		local
			buffer_index_copy, error: INTEGER; entity_name: XT_ENTITY_NAME; source_type: NATURAL_8
		do
			entity_name := parameter_name_cache.item (buf, start_index, end_index)
			if entity_name.is_open then
				Result := Error_recursive_entity_ref; put_boolean (done, True)

			elseif attached parameter_entity_table.item (entity_name) as parameter then
				parameter.set_referenced
				if parameter.is_external then
					do_nothing
				elseif attached parameter.value as value then
					buffer_index_copy := buffer_index -- save field
					buffer_index := 0; source_type := c_accounting_source_type (parse_data)
					entity_name.open
					update_accounting_source_type (parse_data)
					error := process_content (
						value.area, 0, value.count, Byte_type_table, attribute_list, names, declaration_stack,
						element_context, parse_data
					)  -- Recurse

					entity_name.close
					c_set_accounting_source_type (parse_data, source_type) -- restore accounting source type
					buffer_index := buffer_index_copy -- restore field
					set_in_cdata_section (parse_data, False) -- restore state

					inspect error when Error_none then
						do_nothing
					else
						put_boolean (done, True)
					end
					Result := error
				end
			else
				Result := Error_undefined_entity; put_boolean (done, True)
			end
		end

	process_prolog (
		buf: like buffer; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]; attributes: XT_ATTRIBUTE_LIST
		names: like name_cache; declaration_stack: SPECIAL [INTEGER]; parse_data: POINTER
		a_index: TYPED_POINTER [INTEGER]; done: TYPED_POINTER [BOOLEAN]
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
					buf, index, tok_end - 1, token, names, declaration_stack, parse_data, done, $default_case, $common_case
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
								on_xml_declaration (buf, attributes, parse_data)
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
						inspect decl_type when 0 then
							Result := Error_syntax; put_boolean (done, True)
						else
							inspect declaration_stack.count when 0 then
								declaration_stack.extend (decl_type)
							else
								Result := Error_syntax; put_boolean (done, True)
							end
						end

					when Tok_decl_close then
						inspect declaration_stack.count when 1 then
							declaration_stack.remove_tail (1)
							if c_has_dtd_section (parse_data) then
								do_nothing
							else
								Result := on_close_declaration (DOCTYPE, token, parse_data)
								put_boolean (done, Result > 0)
							end
						else
							Result := Error_syntax; put_boolean (done, True)
						end

					when Tok_literal then
						if declaration_stack.count = 1 and then declaration_stack [0] = Doctype then
							document_type_parts_list.extend (buf, index + 1, tok_end - 2, token, newline_or_tab_found)
						else
							Result := name_error (buf, index, end_index, bt_table); put_boolean (done, True)
						end

					when Tok_name then
						if declaration_stack.count = 1 and then declaration_stack [0] = Doctype then
							document_type_parts_list.extend (buf, index, tok_end - 1, token, newline_or_tab_found)
						else
							Result := name_error (buf, index, end_index, bt_table); put_boolean (done, True)
						end

					when Tok_open_bracket then
						if declaration_stack.count = 1 and then attached document_type_parts_list as parts_list then
							set_in_dtd_section (parse_data, True)
							set_has_dtd_section (parse_data, True)
							Result := on_close_declaration (DOCTYPE, token, parse_data)
							put_boolean (done, Result > 0)
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
						on_comment (buf, index + 4, tok_end - 4, parse_data)

					when Tok_invalid then
						Result := Error_invalid_token
					-- Checking for binary data masquerading as XML
						if start_index = 0 and then not is_plausible_xml (buf, start_index, end_index, bt_table)
							and then has_syntax_error (buf, start_index, end_index, bt_table)
						then
							Result := Error_syntax
						end
						put_boolean (done, True)

					when Tok_open_bracket, Tok_close_bracket, tok_open_parenthesis, tok_close_parenthesis, Tok_or, Tok_name_question then
						if declaration_stack.count = 0 then
							Result := Error_syntax; put_boolean (done, True)
						end

					when Tok_pi then
						on_processing_instruction (buf, index + 2, tok_end - 3, attributes, parse_data)
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

	on_close_declaration (declaration, token: INTEGER; parse_data: POINTER): INTEGER
		local
			system_id, public_id, default_value: detachable STRING
		do
			inspect declaration
				when ATTLIST then
					if attached attribute_parts_list as parts_list then
						inspect token when Tok_decl_close then
							if parts_list.is_valid_as_one then
								do_nothing -- legal syntax but does not call handler
							else
								inspect parts_list.count when 4, 5 then
									do_nothing -- already handled when `token /= Tok_decl_close'
								else
									Result := Error_syntax
								end
							end
							parts_list.wipe_out

						else
							if parts_list.last_is_literal and then attached parts_list.last as value then
								default_value := value
								extend_attribute_value_defaults_table (parts_list.element_name, parts_list.name, value)
							end
							if attached parts_list.area as part then
								on_attribute_list_declaration (part [0], part [1], part [2], default_value, parts_list.is_required, parse_data)
							end
							parts_list.reset -- reset to just `element_name'
						end
					end

				when ELEMENT then
					if attached element_parts_list as parts_list and then parts_list.is_valid then
						parts_list.on_close
						if attached parts_list.particle as model then
							on_element_declaration (parts_list.name, model, parse_data)
							parts_list.wipe_out
						else
							Result := Error_syntax
						end
					end

				when ENTITY_ then
					if attached entity_parts_list as parts_list then
						if parts_list.is_valid then
							parts_list.extend_table (entity_table)
							on_entity (parts_list, parse_data)
							parts_list.wipe_out
						else
							Result := Error_syntax
						end
					end

				when DOCTYPE then
					if attached document_type_parts_list as parts_list then
						if parts_list.is_valid then
							parts_list.set_document_type (doctype_identifiers)
							on_doctype_declaration_start (parts_list, c_has_dtd_section (parse_data), parse_data)
							parts_list.wipe_out
						else
							Result := Error_syntax
						end
					end

				when NOTATION_ then
					if attached notation_parts_list as parts_list then
						if parts_list.is_valid then
							if parts_list.is_public then
								if parts_list.valid_index (4) then
									system_id := parts_list [4]
								end
								public_id := parts_list [3]
							else
								system_id := parts_list [3]
							end
							on_notation_declaration (parts_list.name, system_id, public_id, parse_data)
							parts_list.wipe_out
						else
							Result := Error_syntax
						end
					end

				when PARAMETER_ENTITY then
					if attached parameter_entity_parts_list as parts_list then
						if parts_list.is_valid then
							parameter_entity_table.put (parts_list.new_parameter, as_entity_name (parts_list.name))
							on_entity (parts_list, parse_data)
							parts_list.wipe_out
						else
							Result := Error_syntax
						end
					end
			else
			end
		end

	on_entity (parts: XT_ENTITY_PARTS_I; parse_data: POINTER)
		require
			is_valid_list: parts.is_valid
		do
			if not is_predefined_entity (parts.name) then
				on_entity_declaration (
					parts.name, parts.value, parts.system_id, parts.public_id, parts.notation_name,
					parts.is_parameter, parse_data
				)
			end
		end

feature {NONE} -- Implementation

	extend_attribute_value_defaults_table (element_name, attribute_name, value: STRING)
		local
			default_values_list: ARRAYED_LIST [STRING]
		do
			if attached attribute_value_defaults_table as table then
				if attached table [element_name] as list then
					default_values_list := list
				else
					create default_values_list.make (5)
					table.extend (default_values_list, element_name)
				end
				default_values_list.extend (attribute_name)
				default_values_list.extend (value)
			end
		end

	in_prolog_section: BOOLEAN
		do
			Result := parser_data.in_prolog_section
		end

	in_doctype_definition: BOOLEAN
		do
			Result := doctype_declaration_stack.count > 0
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

	expanded_dtd_literal (buf: like buffer; start_index, end_index: INTEGER): detachable STRING
		-- a string with expanded entities or `Void' if nothing expandable in document
		-- type definition
		require
			valid_start_character: Quote_marks.has (buf [start_index])
			valid_end_character: Quote_marks.has (buf [end_index])
		local
			index_buffer: SPECIAL [INTEGER]; entity_buffer: ARRAYED_LIST [XT_ENTITY_NAME]
			amp_index, i: INTEGER; found: BOOLEAN
		do
			amp_index := index_of (buf, '&', start_index, end_index)
			index_buffer := scanned_index_x4_buffer; entity_buffer := scanned_entity_buffer
			if amp_index > -1 then
				entity_buffer.wipe_out
				index_buffer.wipe_out
				inspect scan_attribute_value (buf, start_index, end_index + 1, Byte_type_table, index_buffer, entity_buffer)
					when 0 then
						if attached entity_buffer.area as area then
							from i := 0 until i = area.count or found loop
								if area [i].is_dtd_expandable then
									found := True
								else
									i := i + 1
								end
							end
							if found then
								Result := entity_table.expanded_value (buf, start_index + 1, end_index - 1, area, True, False)
							end
						end
				else end
				index_buffer.wipe_out
			end
		end

	name_error (buf: like buffer; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]): INTEGER
		-- try and agree with eXpat on whether invalid XML will be regarded as a syntax error or invalid token
		-- the assumption is that element_context has been given some binary data masquerading as XML, for example:
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
		-- `True' if document is structured to allow undefined entities to be permitted by conforming element_context
		-- Value is cached in `attribute_intervals.permit_undefined_entities'
		local
			parameter: XT_PARAMETER_ENTITY
		do
			if is_standalone then
				Result := False

			elseif doctype_identifiers.uri.starts_with (Http) then
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
		local
			i: INTEGER
		do
			Precursor {XT_PARSING_BUFFERS}
			Precursor {XT_DOCUMENT_SCANNER}

			attribute_value_defaults_table.wipe_out
			if element_context.has_default_values then
				create element_context.make (parser_data.self_ptr)
			else
				element_context.reset
			end
			parameter_name_cache.reset
			if name_cache /= doctype_name_cache then
				doctype_name_cache.reset
			end

			from i := 0 until i = declaration_parts.count loop
				declaration_parts [i].wipe_out
				i := i + 1
			end
			doctype_declaration_stack.wipe_out
			parameter_entity_table.wipe_out

			doctype_identifiers.uri := Empty_string
			doctype_identifiers.formal_public := Empty_string
		end

feature {NONE} -- Deferred

	process_content (
		buf: like buffer; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]
		attributes: XT_ATTRIBUTE_LIST; names: like name_cache; declaration_stack: SPECIAL [INTEGER]
		a_context: XT_ELEMENT_CONTEXT; parse_data: POINTER
	): INTEGER
		require
			valid_range: start_index >= 0 and then start_index <= end_index
			end_in_buffer: buf = buffer implies end_index <= buffer_end
			buffer_index_at_start: buffer_index = start_index
		deferred
		ensure
			buffer_index_advanced: buffer_index >= start_index and buffer_index <= end_index
		end

feature {NONE} -- Declaration parts

	attribute_parts_list: XT_ATTRIBUTE_PARTS_LIST
		-- For example <!ATTLIST magic priority CDATA "50">

	declaration_parts: SPECIAL [XT_DECLARATION_PARTS_LIST]

	document_type_parts_list: XT_DOCUMENT_TYPE_PARTS_LIST

	element_parts_list: XT_ELEMENT_PARTS_LIST

	entity_parts_list: XT_ENTITY_PARTS_LIST

	notation_parts_list: XT_NOTATION_PARTS_LIST

	parameter_entity_parts_list: XT_PARAMETER_ENTITY_PARTS_LIST

feature {NONE} -- Tables

	attribute_value_defaults_table: HASH_TABLE [ARRAYED_LIST [STRING], STRING]

	parameter_entity_table: HASH_TABLE [XT_PARAMETER_ENTITY, XT_ENTITY_NAME]

feature {NONE} -- Internal attributes

	doctype_name_cache: XT_NAME_CACHE
		-- name cache for use in all DOCTYPE declarations
		-- Normally refers to `name_cache' unless xmlns declarations are resolved
		-- with URI mapping then created separately

	doctype_identifiers: TUPLE [formal_public, uri: STRING]
		-- The two literal strings shown in this example:
		-- <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

	doctype_declaration_stack: SPECIAL [INTEGER]
		-- DOCTYPE declaration type stack

	element_context: XT_ELEMENT_CONTEXT

	parameter_name_cache: XT_PARAMETER_ENTITY_NAME_CACHE
		-- efficient lookup of parameter entity names

	parser_data: XT_PARSER_DATA
		-- allocated memory for C struct `XT_C_PARSE_DATA_STRUCT'

invariant
	name_cache_same_as_declarations_name_cache:
		parser_data.naming_mode = NM_prefix_SEP_localname implies name_cache = doctype_name_cache

	not_name_cache_same_as_declarations_name_cache:
		parser_data.naming_mode /= NM_prefix_SEP_localname implies name_cache /= doctype_name_cache

end
