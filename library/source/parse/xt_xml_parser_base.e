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

feature {NONE} -- Initialization

	make
		do
			create section_flags.make_filled (False, CDATA + 1)
			create element_context.make (section_flags)

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
			reparse_deferral_enabled   := True

			element_depth       			:= 0
			handler_call_depth         := 0
			last_buffer_request_size   := 0
			partial_token_bytes_before := 0
			parse_end_byte_index       := 0

			declaration						:= 0

			section_flags [Prolog] := True
			section_flags [CDATA] := False
		end

feature -- Access

	handler_call_depth: INTEGER

	element_depth: INTEGER

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

	parse_end_byte_index: INTEGER_64
			-- Cumulative count of bytes committed to the parser.

feature -- Status query

	is_final_buffer: BOOLEAN
			-- Was the current parse call marked as the last chunk?

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
				file.parse
				status := file.parse_status
			else
				status := Status_unreadable
			end
		end

	parse (chunk: EL_UTF_8_POINTER_CODEC; a_offset, a_count: INTEGER; a_is_final: BOOLEAN): INTEGER
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
					set_encoded_chunk (chunk, a_count)
					if error_code = Error_not_started then
						status := Status_invalid_document
					else
						parsing_state := State_initialized
						Result := parse (encoded_chunk, 0, encoded_chunk.count, a_is_final) -- Recurse
					end

				when State_suspended then
					error_code := Error_suspended
					Result := Status_error

				when State_finished then
					error_code := Error_finished
					Result := Status_error
			else
			-- State_initialized or State_parsing
				if encoded_chunk /= chunk then
					encoded_chunk.make_shared (chunk.area, a_count)
				end
				parsing_state := State_parsing
				if not call_on_start_parsing then
					Result := Status_error
				elseif not prepare_buffer (encoded_chunk.character_count) then
					Result := Status_error
				else
					write_start := buffer_end
					if a_count > 0 then
					-- Copy caller's bytes into the internal buffer.
					-- Destination index < source index is impossible here
					-- (write_start is past all existing data), so copy_data is safe.
						encoded_chunk.copy_as_utf_8 (buffer, write_start, encoded_chunk.character_count)
					end
					utf_8_copied_count := encoded_chunk.utf_8_copied_count
					remaining_count := encoded_chunk.count - encoded_chunk.last_index
					if remaining_count > 0 then
						encoded_chunk.remove_head (encoded_chunk.last_index)
						if prepare_buffer (utf_8_copied_count + encoded_chunk.character_count) then
							encoded_chunk.copy_as_utf_8 (buffer, write_start + utf_8_copied_count, remaining_count)
							Result := parse_buffer (utf_8_copied_count + encoded_chunk.utf_8_copied_count, a_is_final)
						else
							Result := Status_error
						end
					else
						Result := parse_buffer (encoded_chunk.utf_8_copied_count, a_is_final)
					end
				end
			end
		ensure
			valid_result: Result = Status_ok or Result = Status_error or Result = Status_suspended
			finished_when_final_ok:
				(Result = Status_ok and a_is_final) implies parsing_state = State_finished
			error_code_set_on_error:
				Result = Status_error implies error_code /= Error_none
		end

	put_error (output: IO_MEDIUM; file_path: PATH)
		do
			inspect parsing_state
				when Status_error then
					output.put_string ("Parse error code: " + error_code.out)

				when Status_unreadable then
					output.put_string ("Cannot read: " + file_path.out)
					output.put_new_line
			else
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

					if error_code /= Error_none then
						on_set_error_processor
						Result := Status_error
					else
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
					end
				end
			end
		ensure
			valid_result:
				Result = Status_ok or Result = Status_error or Result = Status_suspended
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
			if element_context.has_attributes then
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

			if enough and then attached buffer as buf and then attached attribute_intervals as attributes
				and then attached scanner as s and then attached name_cache as names
				and then attached element_context as context and then attached section_flags as section
			then
				-- Re-enter loop: drives the processor repeatedly when it sets
				-- the reenter flag (avoids deep C-style recursion).
				from done := False until done loop
					err := process_content (buf, buffer_index, end_index, attributes, s, s.byte_type_table, names, context, section)

					-- Suspended state overrides the reenter request.
					if parsing_state /= State_parsing then
						on_clear_reenter
					end

					if not processor_wants_reenter then
						done := True
					else
						on_clear_reenter
						if err /= Error_none then
							Result := err
							done   := True
						end
					end
				end
				Result := err
			end

			-- Track how many bytes were available but not consumed,
			-- so the deferral heuristic can judge the next call.
			if Result = Error_none then
				if buffer_index = start_index then
					partial_token_bytes_before := have_now
				else
					partial_token_bytes_before := 0
				end
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
		s: like scanner; bt_table: SPECIAL [INTEGER]; names: like name_cache
		a_context: XT_ELEMENT_CONTEXT; section: SPECIAL [BOOLEAN]
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
			context: XT_ELEMENT_CONTEXT
		do
			index := start_index; context := a_context
			from until index >= end_index or done loop
				if section [Prolog] then
					token := s.scan_prolog (buf, bt_table, index, end_index)
					tok_end := s.next_token_index
					inspect token
						when Tok_instance_start then
							if element_context.reached_depth_zero then
								Result := Error_junk_after_doc_element; done := True
							else
								section [Prolog] := False
								if not element_context.has_attributes and then attribute_value_defaults_table.count > 0 then
									create {XT_ELEMENT_ATTRIBUTES_CONTEXT} context.make (section, attribute_value_defaults_table)
									element_context := context
								end
							end

						when Tok_decl_open then
							declaration := select_declaration (buf, index + 2, s)
							declaration_parts_list.wipe_out

						when Tok_literal then
							inspect declaration
								when Entity_ then
									on_entity_declaration_part (buf, index + 1, tok_end - 2, s)
								when Attlist then
									on_attribute_declaration_part (buf, index + 1, tok_end - 2, token, s, names)
							else end

						when Tok_name then
							inspect declaration
								when Entity_ then
									on_entity_declaration_part (buf, index, tok_end - 1, s)
								when Attlist then
									on_attribute_declaration_part (buf, index, tok_end - 1, token, s, names)
							else end

						when Tok_pound_name then
							inspect declaration when Attlist then
								on_attribute_declaration_part (buf, index, tok_end - 1, token, s, names)
							else end

						when Tok_comment then
							on_comment (buf, index + 4, tok_end - 4, attributes)

						when Tok_pi then
							on_processing_instruction (buf, attributes)
							attributes.wipe_out

						when Tok_invalid then
							Result := Error_invalid_token; done := True
					else
						if token <= 0 then
							done := True  -- partial; wait for more data
						else
							index := tok_end  -- skip prolog token
						end
					end
					if not done then
						index := tok_end
					end
				elseif section [CDATA] then
					token := s.scan_cdata_section (buf, bt_table, index, end_index)
					tok_end := s.next_token_index
					inspect token
						when Tok_cdata_sect_close then
							on_cdata_section_close
							section [CDATA] := False
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
					token := s.scan_content (buf, bt_table, index, end_index)
					tok_end := s.next_token_index
					inspect token
						when Tok_cdata_sect_open then
							section [CDATA] := True

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
							if attached s.tag_name (names, buf, index) as tag_name then
								context.push (tag_name)
								on_tag_start (buf, context, attributes, token)
								inspect token when Tok_empty_element_with_attributes then
									attributes.wipe_out
								else
								end
								on_tag_end (tag_name)
								context.pop
							end

						when Tok_end_tag then
							on_tag_end (s.tag_name (names, buf, index + 1))  -- skip '</'
							context.pop

						when Tok_comment then
							on_comment (buf, index + 4, tok_end - 4, attributes)

						when Tok_pi then
							on_processing_instruction (buf, attributes)
							attributes.wipe_out

						when Tok_entity_ref then
							lower := index + 1; upper := tok_end - 2
							code := s.predefined_entity_code (buf, lower, upper)
							inspect code when -1 then
								if attached entity_cache.item (buf, lower, upper) as entity_name
									and then attached entity_table.item (entity_name) as entity_value
								then
									buffer_index_copy := buffer_index -- save field
									buffer_index := 0
									err := process_content (
										entity_value.area, 0, entity_value.count, attributes, s, bt_table, names, context, section
									) -- Recurse
									buffer_index := buffer_index_copy -- restore field
									section [CDATA] := False -- restore state

									if err /= Error_none then
										done := True
									end
									Result := err
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
			buffer_ptr_advanced: buffer_index >= start_index and buffer_index <= end_index
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

	processor_wants_reenter: BOOLEAN
		-- True when the processor has set its reenter flag, requesting
		-- another pass through `process_content' to avoid stack overflow.
		-- Corresponds to `m_reenter' in xmlparse.c.
		do
			Result := False
		end

feature {NONE} -- Event handlers

	on_attribute_declaration_part (
		buf: like buffer; start_index, end_index, token: INTEGER; s: like scanner; names: like name_cache
	)
		local
			default_values_list: ARRAYED_LIST [STRING]
		do
			inspect declaration_parts_list.count
				when 0, 1 then
					declaration_parts_list.extend (names.item (buf, start_index, end_index))
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
							default_values_list.extend (s.new_substring (buf, start_index, end_index))
						end
					when Tok_pound_name then
						declaration_parts_list.extend (names.item (buf, start_index, end_index))

				else
				end
			end
		end

	on_clear_reenter
			-- Clear the reenter flag after each loop iteration.
		do
		ensure
			cleared: not processor_wants_reenter
		end

	on_entity_declaration_part (buf: like buffer; start_index, end_index: INTEGER; s: like scanner)
		do
			inspect declaration_parts_list.count
				when 0 then
					declaration_parts_list.extend (entity_cache.item (buf, start_index, end_index))
				when 1 then
					if s.same_characters (buf, start_index, end_index, SYSTEM) then
						declaration_parts_list.extend (SYSTEM)
					else
						entity_table.put (s.new_substring (buf, start_index, end_index), declaration_parts_list.first)
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

	on_finish (a_status: INTEGER)
		do
		end

	on_set_error_processor
		-- Switch the active processor to the error sink so that any
		-- further parse calls immediately fail.
		-- Corresponds to `m_processor = errorProcessor' in xmlparse.c.
		do
		end

	on_start_parsing: BOOLEAN
			-- Called once when a root parser leaves State_initialized.
			-- Initialise hash salt and any implicit namespace context here.
			-- Return True on success; False causes the parse to abort with
			-- Error_no_memory (matching startParsing() in xmlparse.c).
		do
			Result := True
		end

	on_update_position (start_index, end_index: INTEGER)
			-- Update line/column counters by scanning
			-- `buffer [start_index .. end_index)'.
			-- Corresponds to XmlUpdatePosition() calls in xmlparse.c.
		require
			valid_range: start_index >= 0 and then start_index <= end_index
			to_in_buf: end_index <= buffer_end
		do
		end

feature {NONE} -- Deferred

	on_cdata_section_close
		deferred
		end

	on_comment (buf: like buffer; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		deferred
		end

	on_content (buf: like buffer; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		deferred
		end

	on_tag_end (name: STRING_8)
		deferred
		end

	on_tag_start (buf: like buffer; context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS; token: INTEGER)
		require
			valid_attribute_indices_count: attributes.is_valid_count
		deferred
		end

	on_processing_instruction (buf: SPECIAL [CHARACTER]; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		deferred
		end

feature {NONE} -- Internal attributes

	element_context: XT_ELEMENT_CONTEXT

	section_flags: SPECIAL [BOOLEAN]

	declaration: INTEGER

	last_buffer_request_size: INTEGER

	partial_token_bytes_before: INTEGER

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
