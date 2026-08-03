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

	XT_PARSE_CONSTANTS
		rename
			Element as Element_,
			Entity as Entity_
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

	XT_BYTE_TYPE_CONSTANTS
		export
			{NONE} all
		end

	XT_TOKEN_CONSTANTS
		export
			{NONE} all
		end

	XT_STRING_CONSTANTS
		rename
			CDATA as CDATA_upper
		end

	STRING_HANDLER

feature {NONE} -- Initialisation

	make
		do
			check attached Token_names end

			buffer := new_buffer_area (Default_buffer_size)
			create declaration_parts_list.make (10)
			create attribute_value_defaults_table.make (37)
			create new_line.make_filled ('%N', 1)
			create {EL_UTF_8_C_STRING} encoded_chunk.make_empty

			create scanner.make
			attribute_intervals := scanner.attribute_intervals
			entity_cache := attribute_intervals.entity_cache
			name_cache := attribute_intervals.name_cache
			entity_table := attribute_intervals.entity_table

			set_defaults
		ensure then
			empty_buffer: buffer_end = 0 and buffer_index = 0
		end

	set_defaults
		do
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
			attribute_intervals.wipe_out
			attribute_value_defaults_table.wipe_out
			if not encoded_chunk.is_utf_8 then
				create {EL_UTF_8_C_STRING} encoded_chunk.make_empty
			end
			declaration_parts_list.wipe_out
			entity_cache.reset
			name_cache.reset

			entity_table.wipe_out
			entity_table.set_predefined (entity_cache)
		end

feature {NONE} -- Factory

	new_buffer_area (n: INTEGER): like buffer
		do
			create Result.make_filled ('%U', n + 1)
		ensure
			room_for_null_terminator: Result.count = n + 1
		end

feature {NONE} -- Implementation

	set_encoded_chunk (chunk: EL_UTF_8_POINTER_CODEC; byte_count: INTEGER)
		-- check encoding in XML header calling `set_scanner (Latin_1)' if required
		-- also check if document is actually XML or something weird
		local
			leading, l_chunk: EL_UTF_8_C_STRING; lt_index, gt_index: INTEGER; u: UTF_CONVERTER
			encoding: NATURAL_8; found: BOOLEAN; declaration: STRING
		do
			if attached {EL_UTF_8_C_STRING} encoded_chunk as str then
				l_chunk := str
			else
				create l_chunk.make_empty
			end
			l_chunk.make_shared (chunk.area, byte_count)

			lt_index := l_chunk.index_of ('<', 1)
			if lt_index = 0 then
				error_code := Error_not_started
			else
				leading := l_chunk.substring (1, lt_index - 1)
			-- check leading bytes before first '<'
				across << u.utf_8_bom_to_string_8, u.utf_16le_bom_to_string_8 >> as bom until found loop
					if leading.starts_with (bom) then
						leading.remove_head (bom.count)
						inspect @ bom.cursor_index
							when 1 then
								encoding := Utf_8
						else
							encoding := Utf_16
						end
						found := True
					end
				end
			-- Must exlude /usr/share/app-install/icons/gnome-oregano.svg (Linux Mint 22.2)
			-- The leading bytes are \x89PNG\r\n, which is the PNG magic header, so it's not XML.
				if leading.is_whitespace then
					l_chunk.remove_head (lt_index - 1)
					gt_index := l_chunk.index_of ('>', 1)
					if gt_index > 0 then
						declaration := l_chunk.substring (1, gt_index).to_string
						if encoding = Utf_16 or else declaration.occurrences ('%U') = declaration.count // 2 then
							declaration.extend ('%U')
							declaration := u.utf_16le_string_8_to_string_32 (declaration).to_string_8
							encoding := Utf_16
						end
						declaration.to_upper
						if encoding = 0 and declaration.starts_with (Xml_declaration_upper) then
							encoding := encoding_id (declaration)
						end
					end
					inspect encoding
						when Utf_8 then
							do_nothing

						when Utf_16 then
							create {EL_UTF_16_C_STRING} encoded_chunk.make_shared (l_chunk.area, l_chunk.count)

						when Latin_1, Ascii then
							create {EL_LATIN_1_C_STRING} encoded_chunk.make_shared (l_chunk.area, l_chunk.count)
					else
					end
				else
					error_code := Error_not_started
				end
			end
		end

	encoding_id (declaration: STRING): NATURAL_8
		local
			encoding: NATURAL_8
		do
			Result := Utf_8
			from encoding := Ascii until encoding > Utf_16 loop
				if declaration.has_substring (Encoding_names_upper [encoding.to_integer_32]) then
					Result := encoding
					encoding := Utf_16 + 1 -- break
				else
					encoding := encoding + 1
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

	select_declaration (buf: like buffer; offset: INTEGER; s: like scanner): INTEGER
		do
			across Document_definition_names as name until Result > 0 loop
				if s.same_characters (buf, offset, offset + name.count - 1, name) then
					Result := @ name.cursor_index
				end
			end
		end

	shift_buffer_left (offset: INTEGER)
			-- Slide all live content left by `offset' bytes and adjust
			-- every index that points into `buffer'.
			-- Safe for a forward (left) copy because destination < source.
		require
			positive_offset: offset > 0
			offset_leq_ptr: offset <= buffer_index
		do
			attribute_intervals.shift_buffer_left (buffer, offset)

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

	declaration_parts_list: ARRAYED_LIST [STRING]
		-- For example <!ATTLIST magic priority CDATA "50">
		-- would be: << "magic", "priority", "CDATA", "50" >>

	attribute_intervals: XT_ATTRIBUTE_BUFFER_INTERVALS
		-- collected attribute name-value pair indices into `buffer'

	attribute_value_defaults_table: HASH_TABLE [ARRAYED_LIST [STRING], STRING]

	buffer: SPECIAL [CHARACTER_8]
		-- Raw byte buffer; do not modify indices outside this class.

	encoded_chunk: EL_UTF_8_POINTER_CODEC

	entity_table: XT_ENTITY_TABLE
		-- table of expanded entities defined in DOCTYPE by ENTITY

	entity_cache: XT_ENTITY_NAME_CACHE
		-- efficient lookup of entity names from character buffer interval

	name_cache: XT_NAME_CACHE
		-- efficient lookup of attribute/tag name

	new_line: SPECIAL [CHARACTER_8]

	scanner: XT_DOCUMENT_SCANNER

feature {NONE} -- Constants

	Token_names: ARRAY [STRING]
		once
			Result := <<
				"start_tag_with_attributes",   	-- 1
				"start_tag_no_attributes",     	-- 2
				"empty_element_with_attributes", -- 3
				"empty_element_no_attributes",   -- 4
				"end_tag",          -- 5
				"data_chars",       -- 6
				"data_newline",     -- 7
				"cdata_sect_open",  -- 8
				"entity_ref",       -- 9
				"char_ref",         -- 10
				"pi",               -- 11
				"xml_decl",         -- 12
				"comment",          -- 13
				"bom"               -- 14
			>>
		end

invariant
	room_for_null_terminator: buffer.capacity = buffer_limit + 1
	buffer_indices_consistent:
		buffer_index >= 0 and then buffer_index <= buffer_end and then buffer_end <= buffer_limit

end
