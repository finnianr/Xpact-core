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

	XT_PARSE_EVENTS

	EL_TYPED_POINTER_ROUTINES_I

feature {NONE} -- Initialization

	make
		do
			create section_flags.make_filled (False, section_count)
			create doctype_decl_stack.make_empty (2)
			create element_context.make (section_flags)
			Precursor
		end

	set_defaults
		do
			Precursor
			has_dtd_section			:= False
			is_standalone   	 	   := False

			section_flags [Prolog]	:= True
			section_flags [CDATA]	:= False
		end

feature -- Status query

	is_standalone: BOOLEAN

feature {NONE} -- Token processing

	process_doctype_definition (
		buf: like buffer; index, end_index, token: INTEGER; s: like scanner; names: like name_cache;
		in_section: SPECIAL [BOOLEAN]; a_done, a_default_case, a_common_case: TYPED_POINTER [BOOLEAN]
	): INTEGER
		local
			decl_type: INTEGER; default_case, common_case, done: BOOLEAN
		do
			inspect token
				when Tok_close_bracket then
					if doctype_decl_stack.count = 1 then
						in_section [Doctype_definition] := False
					else
						Result := Error_syntax; done := True
					end

				when Tok_decl_open then
					decl_type := declaration_type (buf, index + 2, s)
					inspect decl_type
						when 0 then
							Result := Error_syntax; done := True
					else
						inspect doctype_decl_stack.count when 1 then
							doctype_decl_stack.extend (decl_type)
							declaration_parts_list.wipe_out
						else
							Result := Error_syntax; done := True
						end
					end

				when Tok_decl_close then
					inspect doctype_decl_stack.count when 2 then
						doctype_decl_stack.remove_tail (1)
					else
						Result := Error_syntax; done := True
					end

				when Tok_name then
					inspect declaration
						when Attlist then
							if doctype_decl_stack.count = 2 then
								on_attribute_declaration_part (buf, index, end_index, token, names, s)
							else
								Result := Error_syntax; done := True
							end

						when Entity_ then
							if doctype_decl_stack.count = 2 then
								on_entity_declaration_part (buf, index, end_index, s)
							else
								Result := Error_syntax; done := True
							end
						when Element_, Notation then
							do_nothing -- for now
					else
						default_case := True
					end

				when Tok_literal then
					inspect declaration
						when Attlist then
							if doctype_decl_stack.count = 2 then
								on_attribute_declaration_part (buf, index + 1, end_index - 1, token, names, s)
							else
								Result := Error_syntax; done := True
							end
						when Entity_ then
							if doctype_decl_stack.count = 2 then
								on_entity_declaration_part (buf, index + 1, end_index - 1, s)
							else
								Result := Error_syntax; done := True
							end

						when Element_, Notation then
							do_nothing -- for now
					else
						default_case := True
					end

				when Tok_pound_name then
					inspect declaration
						when Attlist then
							on_attribute_declaration_part (buf, index, end_index, token, names, s)

						when Element_, Entity_, Notation then
							do_nothing -- for now
					else
						default_case := True
					end
			else
				common_case := True
			end
		-- update local variables in calling routine `process_prolog'
			put_boolean (common_case, a_common_case)
			put_boolean (default_case, a_default_case)
			put_boolean (done, a_done)
		end

	process_prolog (
		buf: like buffer; start_index, end_index: INTEGER; bt_table: SPECIAL [INTEGER]; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS
		s: like scanner; names: like name_cache; in_section: SPECIAL [BOOLEAN]
		index: INTEGER; a_index: TYPED_POINTER [INTEGER]; a_done: TYPED_POINTER [BOOLEAN]
	): INTEGER
		-- process XML prolog from `buf' writing back changes in values to `index' and `done'
		local
			token, tok_end, decl_type: INTEGER; done, default_case, common_case: BOOLEAN
			yes_no: STRING
		do
			token := s.scan_prolog (buf, index, end_index, bt_table)
			tok_end := s.next_token_index
			if in_section [Doctype_definition] then
				Result := process_doctype_definition (buf, index, tok_end - 1, token, s, names, in_section, $done, $default_case, $common_case)
			else
				inspect token
					when Tok_xml_decl then
						if index > 0 then
							Result := Error_misplaced_xml_pi; done := True

						elseif not attributes.has_valid_encoding (buf) then
							Result := Error_unknown_encoding; done := True
						else
							yes_no := attributes.standalone_value (buf)
							if Valid_yes_no.has (yes_no) then
								is_standalone := yes_no [1] = 'y'
								on_xml_declaration (buf, attributes)
								attributes.wipe_out
							else
								Result := Error_xml_decl; done := True
							end
						end

					when Tok_instance_start then
						if element_context.reached_depth_zero then
							Result := Error_junk_after_doc_element; done := True
						else
							in_section [Prolog] := False
							if is_standalone then
								attributes.set_permit_undefined_entities (False)
							else
								attributes.set_permit_undefined_entities (DTD_uri.starts_with (Http))
							end
							if not element_context.has_attributes and then attribute_value_defaults_table.count > 0 then
								create {XT_ELEMENT_ATTRIBUTES_CONTEXT} element_context.make (in_section, attribute_value_defaults_table)
							end
						end

					when Tok_decl_open then
						decl_type := declaration_type (buf, index + 2, s)
						inspect decl_type
							when 0 then
								Result := Error_syntax; done := True
						else
							inspect doctype_decl_stack.count when 0 then
								doctype_decl_stack.extend (decl_type)
								declaration_parts_list.wipe_out
							else
								Result := Error_syntax; done := True
							end
						end

					when Tok_decl_close then
						inspect doctype_decl_stack.count when 1 then
							doctype_decl_stack.remove_tail (1)
							if not has_dtd_section and then not valid_doctype_declaration then
								Result := Error_syntax; done := True
							end
						else
							Result := Error_syntax; done := True
						end

					when Tok_literal then
						if declaration = Doctype and then doctype_decl_stack.count = 1 then
							on_document_declaration_part (buf, index, tok_end - 1, s)
						else
							Result := name_error (buf, index, end_index, s, bt_table); done := True
						end

					when Tok_name then
						if declaration = Doctype and then doctype_decl_stack.count = 1 then
							on_document_declaration_part (buf, index, tok_end - 1, s)
						else
							Result := name_error (buf, index, end_index, s, bt_table); done := True
						end

					when Tok_open_bracket then
						if doctype_decl_stack.count = 1 then
							if valid_doctype_declaration then
								in_section [Doctype_definition] := True
								has_dtd_section := True
							else
								Result := Error_syntax; done := True
							end
						else
							Result := Error_syntax; done := True
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
						if start_index = 0 and then not s.is_plausible_xml (buf, start_index, end_index, bt_table)
							and then s.has_syntax_error (buf, start_index, end_index, bt_table)
						then
							Result := Error_syntax
						end
						done := True

					when Tok_open_bracket, Tok_close_bracket, Tok_open_paren, Tok_close_paren, Tok_or, Tok_name_question then
						if doctype_decl_stack.count = 0 then
							Result := Error_syntax; done := True
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
				if element_context.reached_depth_zero and then not s.is_white_space (buf, index, end_index - 1) then
					Result := Error_junk_after_doc_element; done := True

				elseif token <= 0 then
					done := True  -- partial; wait for more data

				else
				-- skip prolog token					
					put_integer_32 (tok_end, a_index)
				end
			end
			if not done then
				put_integer_32 (tok_end, a_index)
			end
		-- update `done' local variable in calling routine `process_content'
			put_boolean (done, a_done)
		end

feature {NONE} -- Event handlers

	on_attribute_declaration_part (buf: like buffer; start_index, end_index, token: INTEGER; names: like name_cache; s: like scanner)
		local
			default_values_list: ARRAYED_LIST [STRING]; colon_index: INTEGER; s8: XT_STRING_8_ROUTINES
		do
			inspect declaration_parts_list.count
				when 0, 1 then
					colon_index := s8.index_of (buf, ':', start_index, end_index)
					declaration_parts_list.extend (names.item (buf, start_index, end_index, colon_index.max (0)))

				when 2 then
					if s.same_characters (buf, start_index, end_index, CDATA_upper) then
						declaration_parts_list.extend (CDATA_upper)
					end
			else
				inspect token
					when Tok_literal then
						if declaration_parts_list.last = CDATA_upper then
							if attached attribute_value_defaults_table [declaration_parts_list.first] as list then
								default_values_list := list
							else
								create default_values_list.make (5)
								attribute_value_defaults_table.extend (default_values_list, declaration_parts_list.first)
							end
							default_values_list.extend (declaration_parts_list [2])
							default_values_list.extend (s.new_attribute_value (buf, start_index, end_index, s.newline_or_tab_found))
						end
					when Tok_pound_name then
						declaration_parts_list.extend (name_cache.item (buf, start_index, end_index, 0))

				else
				end
			end
		end

	on_entity_declaration_part (buf: like buffer; start_index, end_index: INTEGER; s: like scanner)
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
						if s.newline_or_tab_found then
							create abnormal_string.make (buf, start_index, end_index, s)
							entity_table.put (abnormal_string, declaration_parts_list.first)
						else
							entity_table.put (s.new_substring (buf, start_index, end_index), declaration_parts_list.first)
						end
					end
				when 2 then
					if declaration_parts_list [2] = SYSTEM then
					-- &legal; referenced near end of document /usr/share/gnome/help/synaptic/C/synaptic.xml
					-- Defined as external: <!ENTITY legal SYSTEM "gpl.xml">
					-- Without putting into table there will be a %N missing in output compared to eXpat
						entity_table.put (s.Empty_string, declaration_parts_list.first)
					end
			else
			end
		end

	on_document_declaration_part (buf: like buffer; start_index, end_index: INTEGER; s: like scanner)
		do
			inspect declaration_parts_list.count
				when 0 then
					declaration_parts_list.extend (name_cache.item (buf, start_index, end_index, 0))
				when 1 then
					declaration_parts_list.extend (external_id (buf, start_index, end_index))
				when 2 then
					s.append_area (formal_public_identifier, buf, start_index + 1, end_index - 1)
					declaration_parts_list.extend (formal_public_identifier)
				when 3 then
					s.append_area (DTD_uri, buf, start_index + 1, end_index - 1)
					declaration_parts_list.extend (DTD_uri)
			else
			end
		end

feature {NONE} -- Implementation

	in_prolog_section: BOOLEAN
		do
			Result := section_flags [Prolog]
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

	external_id (buf: like buffer; start_index, end_index: INTEGER): STRING
		-- PUBLIC or SYSTEM id string, defaults to Unknown
		local
			i: INTEGER; s: XT_STRING_8_ROUTINES
		do
			Result := Unknown_id
			from i := 1 until i > Valid_external_id_list.count loop
				if s.same_characters (buf, start_index, end_index, Valid_external_id_list [i]) then
					Result := Valid_external_id_list [i]
					i := 3 -- break
				else
					i := i + 1
				end
			end
		end

	name_error (buf: like buffer; start_index, end_index: INTEGER; s: like scanner; bt_table: SPECIAL [INTEGER]): INTEGER
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
					token := s.scan_prolog (buf, index, end_index, bt_table)
					inspect token
						when Tok_name then
							name_count := name_count + 1
						when Tok_invalid then
							invalid_token := True
					else
						tok_end := s.next_token_index
					end
					if not invalid_token then
						index := tok_end
					end
				end
				if name_count >= 2 then
					Result := Error_syntax

				elseif invalid_token then
					if s.has_syntax_error (buf, index, end_index, bt_table) then
						Result := Error_syntax
					else
						Result := Error_invalid_token
					end
				else
					if s.has_syntax_error (buf, tok_end, end_index, bt_table) then
						Result := Error_syntax
					else
						Result := Error_invalid_token
					end
				end
			end
		end

	reset
		do
			Precursor
			if element_context.has_default_values then
				create element_context.make (section_flags)
			else
				element_context.reset
			end
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

	element_context: XT_ELEMENT_CONTEXT

	doctype_decl_stack: SPECIAL [INTEGER]
		-- DOCTYPE declaration type stack

	has_dtd_section: BOOLEAN
		-- True if prolog has document type definition (DTD) after DOCTYPE x [

	section_flags: SPECIAL [BOOLEAN]
		-- parser section state flags

end
