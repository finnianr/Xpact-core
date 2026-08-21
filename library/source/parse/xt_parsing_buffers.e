note
	description: "XML Parsing buffers"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 20:30:45 GMT (Saturday 20th June 2026)"
	revision: "1"

deferred class
	XT_PARSING_BUFFERS

inherit
	XT_BUFFER_CONSTANTS
		export
			{NONE} all
		end

	XT_PARSE_ERROR_CONSTANTS
		export
			{NONE} all
		end

	XT_ENCODING_TYPE_CONSTANTS
		export
			{NONE} all
		end

	XT_TOKEN_CONSTANTS
		export
			{NONE} all
		end

	XT_STRING_CONSTANTS

feature {NONE} -- Initialization

	make
		do
			check attached Token_names end

			buffer := new_buffer_area (Default_buffer_size)
			create new_line.make_filled ('%N', 1)
			create {XT_UTF_8_CODEC} codec.make_empty

			set_defaults
		ensure then
			empty_buffer: buffer_end = 0 and buffer_index = 0
		end

	set_defaults
		do
			encoding := Unknown_encoding
			parse_end_index := 0
			position_index := 0
			buffer_end := 0
			buffer_index := 0
			error_code := Error_none
			inspect buffer_limit when 0 then
				buffer_limit := Default_buffer_size
			else
				buffer_limit := buffer.capacity - 1
			end
		end

feature -- Access

	buffer_limit: INTEGER
		-- Total usable capacity of `buffer'.

	encoding: NATURAL_8
		-- actual encoding or encoding assumption which may or may not be what is declared
		-- in <?xml ..

	error_code: INTEGER
		-- Most recent error (Error_none if none).

	error_description: STRING
		do
			if attached Error_descriptions.split ('%N') as list and then list.valid_index (error_code) then
				Result := list [error_code]
			else
				create Result.make_empty
			end
		end

feature -- Element change

	reset
		do
			set_defaults

			if not codec.is_utf_8 then
				create {XT_UTF_8_CODEC} codec.make_empty
			end
		end

feature {NONE} -- Factory

	new_buffer_area (n: INTEGER): like buffer
		do
			create Result.make_filled ('%U', n + 1)
		ensure
			room_for_null_terminator: Result.count = n + 1
		end

	new_token_name (token: INTEGER): STRING
		do
			if token > 0 then
				Result := Token_names.split ('%N') [token]
			else
				create Result.make_empty
			end
		end

feature {NONE} -- Implementation

	character_width (a_encoding: INTEGER): INTEGER
		do
			inspect a_encoding
				when UTF_16 then
					Result := 2
			else
				Result := 1
			end
		end

	set_encoding (chunk: XT_C_STRING_CODEC; byte_count: INTEGER)
		-- check encoding in XML header calling `set_scanner (Latin_1)' if required
		-- also check if document is actually XML or something weird
		local
			l_chunk: XT_UTF_8_CODEC; u: UTF_CONVERTER
			found, assumed_utf_8: BOOLEAN; declaration: STRING; declared_encoding: NATURAL_8
		do
			if attached {XT_UTF_8_CODEC} codec as str then
				l_chunk := str
			else
				create l_chunk.make_empty
			end
			l_chunk.make_shared (chunk.area, byte_count)
		-- check for byte order mark if any and remove
			across << u.utf_8_bom_to_string_8, u.utf_16le_bom_to_string_8 >> as bom until found loop
				if l_chunk.starts_with (bom) then
					l_chunk.remove_head (bom.count)
					inspect @ bom.cursor_index
						when 1 then
							encoding := Utf_8
					else
						encoding := Utf_16
					end
					found := True
				end
			end
			declaration := first_element (l_chunk)
			if declaration.is_empty then
				if l_chunk.is_whitespace then
					error_code := Error_no_elements
				end
			else
				if encoding = Utf_16 or else declaration.occurrences ('%U') = declaration.count // 2 then
					declaration.extend ('%U')
					declaration := u.utf_16le_string_8_to_string_32 (declaration).to_string_8
					encoding := Utf_16

				elseif encoding = Unknown_encoding then
					encoding := Utf_8; assumed_utf_8 := True
				end
				if declaration.starts_with (Xml_declaration) and then declaration.has_substring (Encoding_attribute) then
					declaration.to_upper
					declared_encoding := encoding_id (declaration)
					if valid_encoding (declared_encoding) and then valid_encoding (encoding)
						and then character_width (declared_encoding) /= character_width (encoding)
					then
						error_code := Error_incorrect_encoding

					elseif valid_encoding (declared_encoding) and assumed_utf_8 then
						encoding := declared_encoding
					end
				end
				inspect encoding
					when Ascii, Utf_8 then
						do_nothing

					when Utf_16 then
						create {XT_UTF_16_CODEC} codec.make_shared (l_chunk.area, l_chunk.count)

					when Latin_1 then
						create {XT_LATIN_1_CODEC} codec.make_shared (l_chunk.area, l_chunk.count)

				else
				end
			end
		end

	set_error_code (a_error_code: INTEGER)
		do
			error_code := a_error_code
		end

	encoding_id (declaration: STRING): NATURAL_8
		local
			i: NATURAL_8
		do
			from i := Ascii until i > Utf_16 loop
				if declaration.has_substring (Encoding_names_upper [i.to_integer_32]) then
					Result := i
					i := Utf_16 + 1 -- break
				else
					i := i + 1
				end
			end
		end

	first_element (chunk: XT_UTF_8_CODEC): STRING
		local
			lt_index, gt_index: INTEGER; s: XT_STRING_8_ROUTINES
		do
			Result := s.Empty_string
			lt_index := chunk.index_of ('<', 1)
			if lt_index > 0 then
				gt_index := chunk.index_of ('>', lt_index + 1)
				if gt_index > 0 then
					Result := chunk.substring (lt_index, gt_index).to_string
				end
			end
		end

	prepare_buffer (a_count: INTEGER): BOOLEAN
			-- Ensure `buffer' has room for `a_count' more bytes
			-- after `buffer_end'.  Compacts or reallocates as needed,
			-- preserving up to `Context_bytes' before `buffer_index' for
			-- error reporting.  Returns False and sets `error_code' on
			-- failure; buffer indices are adjusted consistently on success.
			--
			-- Corresponds to the resize/compact logic in XML_GetBuffer().
		local
			needed, parsed, keep, offset, new_size: INTEGER
		do
			if a_count <= buffer_limit - buffer_end then
				-- Enough free space after buffer_end already.
				Result := True
			else
				parsed := buffer_index                 -- bytes before buffer_ptr
				keep   := parsed.min (Context_bytes)   -- context bytes to retain
				needed := keep + a_count + (buffer_end - buffer_index)

				if needed < 0 then
					-- Integer overflow: the request is impossibly large.
					error_code := Error_no_memory

				elseif needed <= buffer_limit then
					-- Existing allocation fits once we compact.
					offset := parsed - keep
					if offset > 0 then
						shift_buffer_left (offset)
					end
					Result := True

				else
					-- Must grow. Double from current capacity until large enough.
					new_size := buffer_limit.max (Default_buffer_size)
					from until new_size >= needed or new_size <= 0 loop
						if new_size > {INTEGER}.max_value // 2 then
							new_size := -1   -- overflow sentinel
						else
							new_size := new_size * 2
						end
					end
					if new_size <= 0 then
						error_code := Error_no_memory
					elseif attached new_buffer_area (new_size) as new_buffer then
						new_buffer.copy_data (buffer, 0, 0, buffer_limit)
						buffer := new_buffer
						buffer_limit := new_size
						offset := parsed - keep
						if offset > 0 then
							shift_buffer_left (offset)
						end
						Result := True
					end
				end
			end
		ensure
			space_when_ok:       Result implies buffer_end + a_count <= buffer_limit
			error_when_not_ok:   not Result implies error_code /= Error_none
			ptr_within_end:      buffer_index <= buffer_end
			end_within_lim:      buffer_end <= buffer_limit
			ptr_non_negative:    buffer_index >= 0
		end

	shift_buffer_left (offset: INTEGER)
			-- Slide all live content left by `offset' bytes and adjust
			-- every index that points into `buffer'.
			-- Safe for a forward (left) copy because destination < source.
		require
			positive_offset: offset > 0
			offset_leq_ptr: offset <= buffer_index
		do
			attribute_list.shift_buffer_left (buffer, offset)

			buffer.copy_data (buffer, offset, 0, buffer_end - offset)
			buffer_end := buffer_end - offset
			buffer_index := buffer_index - offset
			position_index := (position_index - offset).max (0)
			parse_end_index := (parse_end_index - offset).max (0)
		ensure
			buffer_ptr_reduced:  buffer_index  = old buffer_index  - offset
			buffer_end_reduced:  buffer_end  = old buffer_end  - offset
			ptr_non_negative:    buffer_index >= 0
			end_non_negative:    buffer_end >= 0
		end

	valid_encoding (a_encoding: INTEGER): BOOLEAN
		do
			inspect a_encoding
				when ASCII .. UTF_16 then
					Result := True
			else
			end
		end

feature {NONE} -- Deferred

	attribute_list: XT_ATTRIBUTE_LIST
		-- collected attribute name-value pair indices into `buffer'
		deferred
		end

feature {NONE} -- Internal attributes

	buffer_end: INTEGER
		-- Index one past the last valid data byte in `buffer'

	buffer_index: INTEGER
		-- Index of the first unprocessed byte in `buffer'

	parse_end_index: INTEGER
		-- Snapshot of buffer_end taken at the top of each parse call.

	position_index: INTEGER
		-- Start index for the next line/column position update.

feature {NONE} -- Internal structures

	buffer: SPECIAL [CHARACTER_8]
		-- Raw byte buffer; do not modify indices outside this class.

	codec: XT_C_STRING_CODEC

	new_line: SPECIAL [CHARACTER_8]

invariant
	room_for_null_terminator: buffer.capacity = buffer_limit + 1
	buffer_indices_consistent:
		buffer_index >= 0 and then buffer_index <= buffer_end and then buffer_end <= buffer_limit

end
