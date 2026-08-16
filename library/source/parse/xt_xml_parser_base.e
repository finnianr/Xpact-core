note
	description: "Incremental XML parser based on eXpat port"
	notes: "See end of class"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 20:30:52 GMT (Saturday 20th June 2026)"
	revision: "1"

deferred class XT_XML_PARSER_BASE

inherit
	XT_PARSING_BUFFERS
		redefine
			make, reset, set_defaults
		end

	XT_PARSE_EVENTS

	EL_TYPED_POINTER_ROUTINES_I

feature {NONE} -- Initialization

	make
		do
			create section_flags.make_filled (False, section_count)
			create element_context.make (section_flags)
			create doctype_decl_stack.make_empty (2)

			Precursor
		ensure then
			set_to_check_encoding: parsing_state = State_check_encoding
			no_error: error_code = Error_none
			handler_clean: handler_call_depth = 0
		end

	set_defaults
		do
			Precursor
			parsing_state              := State_check_encoding
			status 							:= 0

			is_final_buffer            := False
			is_standalone     	      := False
			reparse_deferral_enabled   := True
			has_dtd_section := False

			handler_call_depth         := 0
			last_buffer_request_size   := 0
			partial_token_bytes_before := 0
			parse_end_byte_index       := 0

			section_flags [Prolog] := True
			section_flags [CDATA] := False
		end

feature -- Access

	handler_call_depth: INTEGER

	parsing_state: INTEGER
			-- Current state: one of the State_* constants.

	status: INTEGER
		-- Current state after reading file: one of the Status_* constants.

	status_description: STRING
		do
			if attached Status_names.split ('%N') as list and then list.valid_index (status + 1) then
				Result := list [status + 1]
			else
				create Result.make_empty
			end
		end

feature -- Status query

	is_final_buffer: BOOLEAN
		-- Was the current parse call marked as the last chunk?

	is_standalone: BOOLEAN

feature -- Basic operations

	parse_file (file_path: PATH; chunk_size: INTEGER; collection_off: BOOLEAN)
		local
			file: XT_XML_FILE
		do
			create file.make (file_path, Current)
			if collection_off then
				file.collection_off
			end
			if chunk_size > 0 then
				file.set_chunk_size (chunk_size)
			end
			if file.is_readable then
				file.open_read
				file.parse
				status := file.parse_status
			else
				error_code := Error_file_not_readable
				status := Status_error
			end
		end

	parse (chunk: XT_C_STRING_CODEC; a_offset, a_count: INTEGER; a_is_final: BOOLEAN): INTEGER
		-- Accept `a_count' bytes from `chunk[a_offset]' as the next chunk.
		-- Returns Status_ok, Status_suspended, or Status_error.
		-- Corresponds to XML_Parse() in xmlparse.c.
		require
			non_negative_count: a_count >= 0
			valid_source_range: a_count = 0 or else (a_offset >= 0 and then a_offset + a_count <= chunk.count)
			not_in_handler: handler_call_depth = 0
		local
			write_start, remaining_count, utf_8_copied_count: INTEGER
		do
			inspect parsing_state
				when State_check_encoding then
					set_encoding (chunk, a_count)

					inspect error_code when Error_none then
						parsing_state := State_initialized
						Result := parse (codec, 0, codec.count, a_is_final) -- Recurse
					else
						status := Status_error
					end

				when State_suspended then
					error_code := Error_suspended
					Result := Status_error

				when State_finished then
					error_code := Error_finished
					Result := Status_error
			else
			-- State_initialized or State_parsing
				if codec /= chunk then
					codec.make_shared (chunk.area, a_count)
				end
				parsing_state := State_parsing
				if not call_on_start_parsing then
					Result := Status_error

				elseif not prepare_buffer (codec.character_count) then
					Result := Status_error

				else
					write_start := buffer_end
					if a_count > 0 then
					-- Copy caller's bytes into the internal buffer.
					-- Destination index < source index is impossible here
					-- (write_start is past all existing data), so copy_data is safe.
						codec.copy_as_utf_8 (buffer, write_start, codec.character_count)
						if codec.not_well_formed then
							error_code := Error_invalid_token
							Result := Status_error
						else
							utf_8_copied_count := codec.utf_8_copied_count
							remaining_count := codec.count - codec.last_index
							if remaining_count > 0 then
								codec.remove_head (codec.last_index)
								if prepare_buffer (utf_8_copied_count + codec.character_count) then
									codec.copy_as_utf_8 (buffer, write_start + utf_8_copied_count, remaining_count)
									if codec.not_well_formed then
										error_code := Error_invalid_token
										Result := Status_error
									else
										Result := parse_buffer (utf_8_copied_count + codec.utf_8_copied_count, a_is_final)
									end
								else
									Result := Status_error
								end
							else
								Result := parse_buffer (codec.utf_8_copied_count, a_is_final)
							end
						end
					end
				end
				if a_is_final and then error_code = Error_none and then not element_context.reached_depth_zero then
					error_code := Error_no_elements
					Result := Status_error
				end
			end
		ensure
			valid_result: Status_range.has (Result)
			finished_when_final_ok:
				(Result = Status_ok and a_is_final) implies parsing_state = State_finished
			error_code_set_on_error:
				Result = Status_error implies error_code /= Error_none
		end

	put_error (output: IO_MEDIUM; file_path: PATH)
		do
			if status = Status_error then
				inspect error_code
					when Error_file_not_readable then
						output.put_string ("Cannot read: " + file_path.utf_8_name)
				else
					output.put_string ("Parse error: "); output.put_string (error_description)
				end
				output.put_new_line
			end
		end

feature {NONE} -- Buffer implementation

	parse_buffer (a_count: INTEGER; a_is_final: BOOLEAN): INTEGER
		-- Parse `a_count' bytes that the caller has already written into
		-- `buffer' starting at the old `buffer_end'.
		-- Returns Status_ok, Status_suspended, or Status_error.
		-- Corresponds to XML_ParseBuffer() in xmlparse.c.
		require
			non_negative_count: a_count >= 0
			not_in_handler:     handler_call_depth = 0
			buffer_allocated:   buffer_limit > 0
			data_fits:          buffer_end + a_count <= buffer_limit
		local
			start: INTEGER
		do
			inspect parsing_state
				when State_check_encoding then

				when State_suspended then
					error_code := Error_suspended
					Result := Status_error

				when State_finished then
					error_code := Error_finished
					Result := Status_error
			else
				if not call_on_start_parsing then
					Result := Status_error
				else
					parsing_state        := State_parsing
					start                := buffer_index
					position_index       := start
					buffer_end           := buffer_end + a_count
					parse_end_index      := buffer_end
					parse_end_byte_index := parse_end_byte_index + a_count
					is_final_buffer      := a_is_final

					error_code := call_processor (start, parse_end_index)

					inspect error_code when Error_none then
						inspect parsing_state
							when State_suspended then
								Result := Status_suspended
						else
							if a_is_final then
								parsing_state := State_finished
								on_finish (Status_ok)
							end
							Result := Status_ok
						end
						on_update_position (position_index, buffer_index)
						position_index := buffer_index

					when Error_misplaced_xml_pi then
						on_set_error_processor
						Result := Status_error

					else
						on_set_error_processor
						Result := Status_error
					end
				end
			end
		ensure
			valid_result: Status_range.has (Result)
			finished_when_final_ok:
				(Result = Status_ok and a_is_final) implies parsing_state = State_finished
			error_code_set_on_error:
				Result = Status_error implies error_code /= Error_none
			byte_index_advanced:
				Result /= Status_error implies
					parse_end_byte_index = old parse_end_byte_index + a_count
		end

	get_buffer (a_count: INTEGER): BOOLEAN
			-- Prepare the internal buffer to accept `a_count' more bytes.
			-- On success the caller may write directly into
			-- `buffer [buffer_end .. buffer_end + a_count)'.
			-- Returns False and sets `error_code' on failure.
			--
			-- Corresponds to XML_GetBuffer() in xmlparse.c.
		require
			non_negative_count: a_count >= 0
			not_in_handler:     handler_call_depth = 0
			not_suspended:      parsing_state /= State_suspended
			not_finished:       parsing_state /= State_finished
		do
			last_buffer_request_size := a_count
			Result := prepare_buffer (a_count)
		ensure
			space_when_ok:        Result implies buffer_end + a_count <= buffer_limit
			error_set_on_failure: not Result implies error_code /= Error_none
			request_size_saved:   last_buffer_request_size = a_count
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

feature {NONE} -- Processor dispatch

	call_processor (start_index, end_index: INTEGER): INTEGER
			-- Drive the current processor over `buffer [start_index .. end_index]'.
			-- Implements the reparse-deferral heuristic and the re-enter loop
			-- from callProcessor() in xmlparse.c.
			-- Updates `buffer_index' to the furthest position reached.
			-- Returns Error_none on success or an Error_* code on failure.
		require
			valid_range:  start_index >= 0 and then start_index <= end_index
			end_in_buf:   end_index <= buffer_end
			ptr_at_start: buffer_index = start_index
		local
			err, have_now, had_before, available: INTEGER; enough, done: BOOLEAN
			section: like section_flags; context: like element_context; s: like scanner
			names: like name_cache; attributes: like attribute_intervals; buf: like buffer
		do
			have_now := end_index - start_index

			-- Reparse-deferral heuristic (m_reparseDeferralEnabled in xmlparse.c):
			-- avoid re-scanning a partial token until we have significantly more data
			-- or the buffer is nearly full.
			if reparse_deferral_enabled and then not is_final_buffer then
				had_before := partial_token_bytes_before
				available  := (buffer_index - buffer_index.min (Context_bytes)) + (buffer_limit - buffer_end)
				enough := have_now >= 2 * had_before
					or else last_buffer_request_size > available
				if not enough then
					-- Leave buffer_ptr at start_index; nothing consumed this call.
					Result := Error_none
				end
			else
				enough := True
			end
			if enough then
				-- Re-enter loop: drives the processor repeatedly when it sets
				-- the reenter flag (avoids deep C-style recursion).
				section := section_flags; context := element_context; s := scanner; names := name_cache
				attributes := attribute_intervals; buf := buffer

				from done := False until done loop
					err := process_content (buf, buffer_index, end_index, attributes, s, names, context, section)

					-- Suspended state overrides the reenter request.
					inspect parsing_state when State_parsing then
						do_nothing
					else
						on_clear_reenter
					end

					if not processor_wants_reenter then
						done := True
					else
						on_clear_reenter
						inspect err when Error_none then
							do_nothing
						else
							Result := err
							done := True
						end
					end
				end
				Result := err
			end

			-- Track how many bytes were available but not consumed,
			-- so the deferral heuristic can judge the next call.
			inspect Result when Error_none then
				if buffer_index = start_index then
					partial_token_bytes_before := have_now
				else
					partial_token_bytes_before := 0
				end
			else
			end
		ensure
			buffer_ptr_in_range: buffer_index >= start_index and buffer_index <= end_index
			error_code_unchanged_on_success: Result = Error_none
				implies error_code = old error_code
		end

	call_on_start_parsing: BOOLEAN
			-- If currently in State_initialized, call `on_start_parsing' for a
			-- root parser; always succeeds for child/entity parsers.
			-- Returns False only when `on_start_parsing' fails.
		do
			if parsing_state = State_initialized then
				if not on_start_parsing then
					error_code := Error_no_memory
				else
					Result := True
				end
			else
				Result := True
			end
		ensure
			error_set_on_failure: not Result implies error_code /= Error_none
		end

	process_content (
		buf: like buffer; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS
		s: like scanner; names: like name_cache
		a_context: XT_ELEMENT_CONTEXT; in_section: SPECIAL [BOOLEAN]
	): INTEGER
		-- Scan tokens from `buf' `start_index .. end_index` and triggers relevant XML events.  Advances `buffer_index'.
		-- Execute one pass of the current processor over `buf [start_index .. end_index)'.
		-- Must update `buffer_index' to the first unconsumed byte.
		-- Returns Error_none on success or an Error_* code on failure.
		-- Corresponds to a single call of `m_processor' in xmlparse.c.
		require
			valid_range: start_index >= 0 and then start_index <= end_index
			end_in_buffer: buf = buffer implies end_index <= buffer_end
			buffer_index_at_start: buffer_index = start_index
		local
			index, token, tok_end, code, err, buffer_index_copy, lower, upper: INTEGER; done: BOOLEAN
			context: XT_ELEMENT_CONTEXT; tag_name, entity_name: STRING; bt_table: SPECIAL [INTEGER]
		do
			index := s.index_of (buf, (85).to_character_8, start_index, end_index)
			bt_table := s.Byte_type_table
			index := start_index; context := a_context
			from until index >= end_index or done loop
				if in_section [Prolog] then
					Result := process_prolog (
						buf, start_index, end_index, bt_table, attributes, s, names, in_section, index, $index, $done
					)
					context := element_context

				elseif in_section [CDATA] then
					token := s.scan_cdata_section (buf, index, end_index, bt_table)
					tok_end := s.next_token_index
					inspect token
						when Tok_cdata_sect_close then
							on_cdata_section_close
							in_section [CDATA] := False
							index := tok_end

						when Tok_data_chars then
							on_content (buf, index, tok_end - 1, attributes)
							index := tok_end

						when Tok_data_newline then
							on_content (new_line, 0, 0, attributes)
							index := tok_end

					else
						if token = Tok_invalid then
							Result := Error_invalid_token; done := True
						else
							done := True  -- partial; wait for more data
						end
					end
				else
					token := s.scan_content (buf, index, end_index, bt_table)
					tok_end := s.next_token_index
					inspect token
						when Tok_cdata_sect_open then
							in_section [CDATA] := True

						when Tok_invalid then
							Result := Error_invalid_token; done := True

						when Tok_data_chars then
							on_content (buf, index, tok_end - 1, attributes)

						when Tok_data_newline then
							on_content (new_line, 0, 0, attributes)

						when Tok_start_tag_no_attributes then
							context.push (s.tag_name (names, buf, index))
							on_tag_start (buf, context, attributes, token)

						when Tok_start_tag_with_attributes then
							context.push (s.tag_name (names, buf, index))
							on_tag_start (buf, context, attributes, token)
							attributes.wipe_out

						when Tok_empty_element_with_attributes, Tok_empty_element_no_attributes then
							tag_name := s.tag_name (names, buf, index)
							context.push (tag_name)
							on_tag_start (buf, context, attributes, token)
							inspect token when Tok_empty_element_with_attributes then
								attributes.wipe_out
							else
							end
							on_tag_end (tag_name)
							inspect context.pop (tag_name) when Error_tag_mismatch then
								Result := Error_tag_mismatch; done := True
							else
							end

						when Tok_end_tag then
							tag_name := s.tag_name (names, buf, index + 1)
							on_tag_end (tag_name)  -- skip '</'
							inspect context.pop (tag_name) when Error_tag_mismatch then
								Result := Error_tag_mismatch; done := True
							else
							end

						when Tok_comment then
							on_comment (buf, index + 4, tok_end - 4, attributes)

						when Tok_pi then
							on_processing_instruction (buf, index + 2, tok_end - 3, attributes)
							attributes.wipe_out

						when Tok_entity_ref then
							lower := index + 1; upper := tok_end - 2
							code := s.predefined_entity_code (buf, lower, upper)
							inspect code when -1 then
								entity_name := entity_cache.item (buf, lower, upper)
								if attached entity_table.item (entity_name, False) as entity_value then
									buffer_index_copy := buffer_index -- save field
									buffer_index := 0
									err := process_content (
										entity_value.area, 0, entity_value.count, attributes, s, names, context, in_section
									) -- Recurse
									buffer_index := buffer_index_copy -- restore field
									in_section [CDATA] := False -- restore state

									inspect err when Error_none then
										do_nothing
									else
										done := True
									end
									Result := err

								elseif attributes.permit_undefined_entities then
									do_nothing
								else
									Result := Error_undefined_entity; done := True
								end
							else
								on_content (s.unescaped (code), 0, 0, attributes)
							end

						when Tok_char_ref then
							-- index is '&'; tok_end is exclusive end past ';'
							code := s.char_ref_number (buf, index, tok_end)
							inspect s.valid_char_ref (code) when -1 then
								Result := Error_bad_char_ref; done := True
							else
								if attached s.utf_8_encoded (code) as l_utf_8 then
									on_content (l_utf_8, 0, l_utf_8.count - 1, attributes)
								end
							end
					else
						if token < 0 then
							Result := s.error_code
							done := True  -- partial; wait for more data
						end
					end
					if not done then
						index := tok_end
					end
				end
			end
			buffer_index := index
		ensure
			buffer_index_advanced: buffer_index >= start_index and buffer_index <= end_index
		end

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

feature {NONE} -- Implementation

	in_prolog_section: BOOLEAN
		do
			Result := section_flags [Prolog]
		end

	in_cdata_section: BOOLEAN
		do
			Result := section_flags [CDATA]
		end

	in_doctype_definition: BOOLEAN
		do
			Result := doctype_decl_stack.count > 0
		end

feature {NONE} -- Implementation

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

	increment_handler_depth
		-- Signal entry into a parse-event callback.
		require
			parsing_active: parsing_state = State_parsing
		do
			handler_call_depth := handler_call_depth + 1
		ensure
			depth_increased: handler_call_depth = old handler_call_depth + 1
		end

	decrement_handler_depth
		-- Signal exit from a parse-event callback.
		require
			in_handler: handler_call_depth > 0
		do
			handler_call_depth := handler_call_depth - 1
		ensure
			depth_decreased: handler_call_depth = old handler_call_depth - 1
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

feature {NONE} -- Internal attributes

	has_dtd_section: BOOLEAN
		-- True if prolog has document type definition (DTD) after DOCTYPE x [

	element_context: XT_ELEMENT_CONTEXT

	section_flags: SPECIAL [BOOLEAN]
		-- parser section state flags

	doctype_decl_stack: SPECIAL [INTEGER]
		-- DOCTYPE declaration type stack

	last_buffer_request_size: INTEGER

	partial_token_bytes_before: INTEGER

	parse_end_byte_index: INTEGER_64
		-- Cumulative count of bytes committed to the parser.

	reparse_deferral_enabled: BOOLEAN

invariant
	valid_state: Parsing_states.has (parsing_state)
	position_index_non_negative: position_index >= 0
	non_negative_handler_depth: handler_call_depth >= 0
	non_negative_byte_index: parse_end_byte_index >= 0
	partial_token_non_negative: partial_token_bytes_before >= 0

note
	notes: "[
		Ports XML_Parse(), XML_ParseBuffer(), XML_GetBuffer(), and callProcessor()
		from xmlparse.c (libexpat 2.x) to Eiffel with Design by Contract.

		Pointer arithmetic from the C source is replaced by integer indices
		into `buffer: SPECIAL [CHARACTER]'.  The correspondences are:

		  C field              Eiffel attribute
		  -----------------------------------------------------------------------
		  m_buffer[0]          buffer [0]
		  m_bufferPtr          buffer_ptr        (index)
		  m_bufferEnd          buffer_end        (index)
		  m_bufferLim          buffer_lim        (capacity)
		  m_parseEndPtr        parse_end_ptr     (index, snapshot at parse entry)
		  m_positionPtr        position_ptr      (index for line/col tracking)
		  m_parseEndByteIndex  parse_end_byte_index
		  m_handlerCallDepth   handler_call_depth
		  m_partialTokenBytesBefore  partial_token_bytes_before
		  m_lastBufferRequestSize    last_buffer_request_size
		  m_reparseDeferralEnabled   reparse_deferral_enabled
		  m_parsingStatus.parsing    parsing_state
		  m_parsingStatus.finalBuffer  is_final_buffer
		  m_errorCode          error_code

		Deferred features that concrete subclasses must supply:
			on_comment (text: C_STRING_8)
			on_content (text_intervals: XT_STRING_INTERVALS)
			on_tag_attributes
			on_tag_end (name: STRING_8)
			on_tag_start (name: STRING_8; is_empty: BOOLEAN)


		Optional features that concrete subclasses can redefine:
			on_start_parsing     	-- initialise hash salt, namespace context (startParsing)
			on_clear_reenter     	-- clear the reenter flagon_finish (status: INTEGER)
			on_set_error_processor  -- switch to errorProcessor sink
			on_update_position   	-- run XmlUpdatePosition over consumed bytes
	]"

end
