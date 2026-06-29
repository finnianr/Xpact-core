note
	description: "Incremental XML parser based on eXpat port"
	notes: "See end of class"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 20:30:52 GMT (Saturday 20th June 2026)"
	revision: "1"

deferred class XT_XML_PARSER

inherit
	XT_STRING_BUFFERS
		redefine
			make
		end

	XT_BYTE_TYPE_CONSTANTS
		export
			{NONE} all
		end

	XT_TOKEN_CONSTANTS
		export
			{NONE} all
		end

	STRING_HANDLER

feature {NONE} -- Initialisation

	make
			-- Set up in State_initialized with an empty buffer.
		do
			parsing_state              := State_initialized

			is_final_buffer            := False
			in_prolog						:= True
			in_cdata_section           := False
			reparse_deferral_enabled   := True

			handler_call_depth         := 0
			last_buffer_request_size   := 0
			partial_token_bytes_before := 0
			parse_end_byte_index       := 0

			Precursor
		ensure then
			initialized:    parsing_state = State_initialized
			no_error:       error_code = Error_none
			handler_clean:  handler_call_depth = 0
		end

feature -- Access

	handler_call_depth: INTEGER

feature -- Access

	parsing_state: INTEGER
			-- Current state: one of the State_* constants.

	parse_end_byte_index: INTEGER_64
			-- Cumulative count of bytes committed to the parser.

feature -- Status query

	is_final_buffer: BOOLEAN
			-- Was the current parse call marked as the last chunk?

	in_prolog: BOOLEAN

	in_cdata_section: BOOLEAN


feature -- Basic operations

	parse (s: SPECIAL [CHARACTER]; a_offset, a_count: INTEGER; a_is_final: BOOLEAN): INTEGER
			-- Accept `a_count' bytes from `s[a_offset]' as the next chunk.
			-- Returns Status_ok, Status_suspended, or Status_error.
			-- Corresponds to XML_Parse() in xmlparse.c.
		require
			non_negative_count: a_count >= 0
			valid_source_range: a_count = 0 or else (a_offset >= 0 and then a_offset + a_count <= s.count)
			not_in_handler: handler_call_depth = 0
		local
			write_start: INTEGER
		do
			inspect parsing_state
				when State_suspended then
					error_code := Error_suspended
					Result := Status_error
				when State_finished then
					error_code := Error_finished
					Result := Status_error
			else
			-- State_initialized or State_parsing
				parsing_state := State_parsing
				if not call_on_start_parsing then
					Result := Status_error
				elseif not prepare_buffer (a_count) then
					Result := Status_error
				else
					write_start := buffer_end
					if a_count > 0 then
						-- Copy caller's bytes into the internal buffer.
						-- Destination index < source index is impossible here
						-- (write_start is past all existing data), so copy_data is safe.
						buffer.copy_data (s, a_offset, write_start, a_count)
					end
					Result := parse_buffer (a_count, a_is_final)
				end
			end
		ensure
			valid_result: Result = Status_ok or Result = Status_error or Result = Status_suspended
			finished_when_final_ok:
				(Result = Status_ok and a_is_final) implies parsing_state = State_finished
			error_code_set_on_error:
				Result = Status_error implies error_code /= Error_none
		end

	reset
		do
			make
		end

feature -- Handler depth tracking

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

feature {NONE} -- Buffer implementation

	parse_buffer (a_count: INTEGER; a_is_final: BOOLEAN): INTEGER
		-- Parse `a_count' bytes that the caller has already written into
		-- `buffer' starting at the old `buffer_end'.
		-- Returns Status_ok, Status_suspended, or Status_error.
		--
		-- Corresponds to XML_ParseBuffer() in xmlparse.c.
		require
			non_negative_count: a_count >= 0
			not_in_handler:     handler_call_depth = 0
			buffer_allocated:   buffer_lim > 0
			data_fits:          buffer_end + a_count <= buffer_lim
		local
			start: INTEGER
		do
			inspect parsing_state
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
			space_when_ok:        Result implies buffer_end + a_count <= buffer_lim
			error_set_on_failure: not Result implies error_code /= Error_none
			request_size_saved:   last_buffer_request_size = a_count
		end


feature {NONE} -- Processor dispatch

	call_processor (a_start, a_end_index: INTEGER): INTEGER
			-- Drive the current processor over `buffer[a_start .. a_end_index)'.
			-- Implements the reparse-deferral heuristic and the re-enter loop
			-- from callProcessor() in xmlparse.c.
			-- Updates `buffer_index' to the furthest position reached.
			-- Returns Error_none on success or an Error_* code on failure.
		require
			valid_range:  a_start >= 0 and then a_start <= a_end_index
			end_in_buf:   a_end_index <= buffer_end
			ptr_at_start: buffer_index = a_start
		local
			have_now, had_before, available: INTEGER
			enough, done: BOOLEAN
			err: INTEGER
		do
			have_now := a_end_index - a_start

			-- Reparse-deferral heuristic (m_reparseDeferralEnabled in xmlparse.c):
			-- avoid re-scanning a partial token until we have significantly more data
			-- or the buffer is nearly full.
			if reparse_deferral_enabled and then not is_final_buffer then
				had_before := partial_token_bytes_before
				available  := (buffer_index - buffer_index.min (Context_bytes)) + (buffer_lim - buffer_end)
				enough := have_now >= 2 * had_before
					or else last_buffer_request_size > available
				if not enough then
					-- Leave buffer_ptr at a_start; nothing consumed this call.
					Result := Error_none
				end
			else
				enough := True
			end

			if enough and then attached buffer as buf and then attached attribute_intervals as attributes
				and then attached text_data_intervals as text_data
			then
				-- Re-enter loop: drives the processor repeatedly when it sets
				-- the reenter flag (avoids deep C-style recursion).
				from done := False until done loop
					err := do_process_bytes (buf, attributes, text_data, buffer_index, a_end_index)

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
				if buffer_index = a_start then
					partial_token_bytes_before := have_now
				else
					partial_token_bytes_before := 0
				end
			end
		ensure
			buffer_ptr_in_range: buffer_index >= a_start and buffer_index <= a_end_index
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

	do_process_bytes (
		buf: like buffer; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS; text_data: XT_TEXT_DATA_BUFFER_INTERVALS
		a_start, a_end_index: INTEGER
	): INTEGER
		-- Scan tokens from `buf' `a_start .. a_end_index` and
		-- triggers relevant XML events.  Advances `buffer_ptr'.
		-- Execute one pass of the current processor over
		-- `buf [a_start .. a_end_index)'.
		-- Must update `buffer_index' to the first unconsumed byte.
		-- Returns Error_none on success or an Error_* code on failure.
		-- Corresponds to a single call of `m_processor' in xmlparse.c.
		require
			valid_range:    a_start >= 0 and then a_start <= a_end_index
			end_in_buf:     a_end_index <= buffer_end
			ptr_at_start:   buffer_index = a_start
		local
			index, tok: INTEGER; done: BOOLEAN; lower_upper: SPECIAL [INTEGER]
		do
			index := a_start; create lower_upper.make_empty (2)
			from until index >= a_end_index or done loop
				if in_prolog then
					tok := encoding.scan_prolog (buf, index, a_end_index)
					inspect tok
						when Tok_instance_start then
							in_prolog := False
							index := encoding.next_token_index

						when Tok_invalid then
							Result := Error_invalid_token; done := True
					else
						if tok <= 0 then
							done := True  -- partial; wait for more data
						else
							index := encoding.next_token_index  -- skip prolog token
						end
					end
				elseif in_cdata_section then
					tok := encoding.scan_cdata_section (buf, index, a_end_index)
					inspect tok
						when Tok_cdata_sect_close then
							in_cdata_section := False
							index := encoding.next_token_index

						when Tok_data_chars, Tok_data_newline then
							lower_upper.extend (index); lower_upper.extend (encoding.next_token_index - 1)
							text_data.transfer (lower_upper)
							index := encoding.next_token_index

					else
						if tok = Tok_invalid then
							Result := Error_invalid_token; done := True
						else
							done := True  -- partial; wait for more data
						end
					end
				else
					tok := encoding.scan_content (buf, index, a_end_index)
					inspect tok
						when Tok_cdata_sect_open then
							in_cdata_section := True; text_data.set_is_c_data
							index := encoding.next_token_index

						when Tok_invalid then
							Result := Error_invalid_token; done := True
					else
						if tok > 0 then
							process_token (buf, attributes, text_data, lower_upper, tok, index)
							index := encoding.next_token_index
						else
							done := True  -- partial; wait for more data
						end
					end
				end
			end
			buffer_index := index
		ensure
			buffer_ptr_advanced: buffer_index >= a_start and buffer_index <= a_end_index
		end

	process_comment (buf: like buffer; str: C_STRING_8; lower, upper: INTEGER)
		local
			null_index: INTEGER; c, null: CHARACTER
		do
			str.make_shared (buf.item_address (lower), upper - lower + 1)
			null_index := upper + 1
			c := buf [null_index]; buf [null_index] := null
			on_comment (str) -- null terminated temporarily for C strlen
			buf [null_index] := c
		end

	process_token (
		buf: like buffer; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS; text_data: XT_TEXT_DATA_BUFFER_INTERVALS
		lower_upper: SPECIAL [INTEGER]; tok, tok_start: INTEGER
	)
		-- Process an XML event for a complete token at tok_start.
		-- `encoding.next_token_index' is the first byte after the token.
		local
			tok_end: INTEGER
		do
			tok_end := encoding.next_token_index
			inspect tok
				when Tok_data_chars then
					do_nothing
			else
				if text_data.index_count > 0 then
					on_content (text_data)
					text_data.wipe_out
				end
			end
			inspect tok
				when Tok_start_tag_no_attributes then
					on_tag_start (encoding.tag_name (buf, tok_start +  1), attributes)

				when Tok_start_tag_with_attributes then
					on_tag_start (encoding.tag_name (buf, tok_start +  1), attributes)
					attributes.wipe_out

				when Tok_empty_element_with_attributes, Tok_empty_element_no_attributes then
					if attached encoding.tag_name (buf, tok_start +  1) as tag_name then
						on_tag_start (tag_name, attributes)
						inspect tok when Tok_empty_element_with_attributes then
							attributes.wipe_out
						else
						end
						on_tag_end (tag_name)
					end

				when Tok_end_tag then
					on_tag_end (encoding.tag_name (buf, tok_start + 2))  -- skip '</'

				when Tok_comment then
					process_comment (buf, comment_string, tok_start + 4, tok_end - 4)

				when Tok_data_chars then
					lower_upper.extend (tok_start); lower_upper.extend (tok_end - 1)
					text_data.transfer (lower_upper)

			else
				-- PIs, BOM, xml declaration, CDATA open: skip
			end
		end

feature {NONE} -- Implementation

	is_quote_or_apostrophe (bt: INTEGER): BOOLEAN
		do
			inspect bt
				when BT_quote, BT_apostrophe then
					Result := True
			else
			end
		end

	not_name_character (bt: INTEGER): BOOLEAN
		do
			inspect bt
				when BT_CR, BT_LF, BT_gt, BT_equals, BT_forward_slash, BT_whitespace then
					Result := True
			else
			end
		end

	processor_wants_reenter: BOOLEAN
		-- True when the processor has set its reenter flag, requesting
		-- another pass through `do_process_bytes' to avoid stack overflow.
		-- Corresponds to `m_reenter' in xmlparse.c.
		do
			Result := False
		end

feature {NONE} -- Event handlers

	on_finish (status: INTEGER)
		do
		end

	on_set_error_processor
		-- Switch the active processor to the error sink so that any
		-- further parse calls immediately fail.
		-- Corresponds to `m_processor = errorProcessor' in xmlparse.c.
		do
		end

	on_clear_reenter
			-- Clear the reenter flag after each loop iteration.
		do
		ensure
			cleared: not processor_wants_reenter
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

feature {NONE} -- Deferred event handlers

	on_comment (text: C_STRING_8)
		require
			null_terminated: is_null_terminated (text)
		deferred
		end

	on_content (text_intervals: XT_CHARACTER_BUFFER_INTERVALS)
		deferred
		end

	on_tag_end (name: STRING_8)
		deferred
		end

	on_tag_start (name: STRING_8; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		require
			valid_attribute_indices_count: attributes.is_valid_count
		deferred
		end

feature {NONE} -- Internal attributes

	last_buffer_request_size: INTEGER

	partial_token_bytes_before: INTEGER

	reparse_deferral_enabled: BOOLEAN

invariant
	room_for_null_terminator: buffer.capacity = buffer_lim + 1
	valid_state:
		parsing_state = State_initialized or parsing_state = State_parsing
		or parsing_state = State_finished or parsing_state = State_suspended

	buffer_indices_consistent:
		buffer_index >= 0 and then buffer_index <= buffer_end and then buffer_end <= buffer_lim

	position_ptr_non_negative: position_index >= 0
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
