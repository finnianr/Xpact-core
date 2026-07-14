note
	description: "String buffering"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 20:30:45 GMT (Saturday 20th June 2026)"
	revision: "1"

deferred class
	XT_STRING_BUFFERS

inherit
	XT_BUFFER_CONSTANTS
		export
			{NONE} all
		end

	XT_PARSE_CONSTANTS
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

	STRING_HANDLER

feature {NONE} -- Initialisation

	make
		do
			parse_end_index := 0
			position_index := 0
			buffer_end := 0
			buffer_index := 0
			error_code := Error_none
			buffer_lim := Default_buffer_size

			check attached Token_names end

			buffer := new_buffer_area (Default_buffer_size)
			create last_entity_ref.make_empty
			set_scanner (Utf_8)

		ensure then
			empty_buffer: buffer_end = 0 and buffer_index = 0
		end

feature -- Access

	buffer_lim: INTEGER
		-- Total usable capacity of `buffer'.

	error_code: INTEGER
		-- Most recent error (Error_none if none).

feature -- Element change

	set_scanner (type: NATURAL_8)
		do
			scanner := new_scanner (type)
			attribute_intervals := scanner.attribute_intervals
			name_cache := attribute_intervals.name_cache
			entity_table := attribute_intervals.entity_table
		end

feature {NONE} -- Factory

	new_buffer_area (n: INTEGER): like buffer
		do
			create Result.make_filled ('%U', n + 1)
		ensure
			room_for_null_terminator: Result.count = n + 1
		end

	new_scanner (type: NATURAL_8): XT_DOCUMENT_SCANNER
		do
			inspect type
				when Ascii then
					create {XT_ASCII_SCANNER} Result.make
				when Latin_1 then
					create {XT_LATIN_1_SCANNER} Result.make
			else
				check
					type_utf_8: type = Utf_8
				end
				create {XT_UTF_8_SCANNER} Result.make
			end
		end

feature {NONE} -- Implementation

	is_null_terminated (text: C_STRING_8): BOOLEAN
		local
			c: CHARACTER
		do
			(text.area + text.count).memory_copy ($c, 1)
			Result := c = '%U'
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
			if a_count <= buffer_lim - buffer_end then
				-- Enough free space after buffer_end already.
				Result := True
			else
				parsed := buffer_index                 -- bytes before buffer_ptr
				keep   := parsed.min (Context_bytes)   -- context bytes to retain
				needed := keep + a_count + (buffer_end - buffer_index)

				if needed < 0 then
					-- Integer overflow: the request is impossibly large.
					error_code := Error_no_memory

				elseif needed <= buffer_lim then
					-- Existing allocation fits once we compact.
					offset := parsed - keep
					if offset > 0 then
						shift_buffer_left (offset)
					end
					Result := True

				else
					-- Must grow. Double from current capacity until large enough.
					new_size := buffer_lim.max (Default_buffer_size)
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
						new_buffer.copy_data (buffer, 0, 0, buffer_lim)
						buffer := new_buffer
						buffer_lim := new_size
						offset := parsed - keep
						if offset > 0 then
							shift_buffer_left (offset)
						end
						Result := True
					end
				end
			end
		ensure
			space_when_ok:       Result implies buffer_end + a_count <= buffer_lim
			error_when_not_ok:   not Result implies error_code /= Error_none
			ptr_within_end:      buffer_index <= buffer_end
			end_within_lim:      buffer_end <= buffer_lim
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

	attribute_intervals: XT_ATTRIBUTE_BUFFER_INTERVALS
		-- collected attribute name-value pair indices into `buffer'

	buffer: SPECIAL [CHARACTER_8]
		-- Raw byte buffer; do not modify indices outside this class.

	entity_table: HASH_TABLE [STRING, STRING]
		-- table of expanded entities defined in DOCTYPE by ENTITY

	last_entity_ref: STRING

	name_cache: XT_NAME_CACHE
		-- efficient lookup of attribute/tag name

	scanner: XT_DOCUMENT_SCANNER

feature {NONE} -- Element content tokens (positive)

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
end
