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
	XT_BUFFER_CONSTANTS; XT_PARSE_CONSTANTS; XT_ENCODING_TYPE_CONSTANTS

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

			buffer := new_buffer_area (Default_buffer_size)
			set_encoding (Utf_8)

			create attribute_table.make (11)
			create comment_string.make_shared (default_pointer, 0)
			create output_buffer.make (10)
			create text_data_intervals.make (5)

		ensure then
			empty_buffer: buffer_end = 0 and buffer_index = 0
		end

feature -- Access

	buffer_lim: INTEGER
		-- Total usable capacity of `buffer'.

	error_code: INTEGER
		-- Most recent error (Error_none if none).

feature -- Element change

	set_encoding (type: NATURAL_8)
		do
			encoding := new_encoding (type)
			attribute_intervals := encoding.attribute_intervals
			name_cache := encoding.name_cache
		end

feature {NONE} -- Factory

	new_buffer_area (n: INTEGER): like buffer
		do
			create Result.make_filled ('%U', n + 1)
		ensure
			room_for_null_terminator: Result.count = n + 1
		end

	new_encoding (type: NATURAL_8): XT_NORMAL_ENCODING
		do
			inspect type
				when Ascii then
					create {XT_ASCII_ENCODING} Result.make
				when Latin_1 then
					create {XT_LATIN1_ENCODING} Result.make
			else
				check
					type_utf_8: type = Utf_8
				end
				create {XT_UTF8_ENCODING} Result.make
			end
		end

feature {NONE} -- Implementation

	adjusted_concatenation (text_intervals: XT_TEXT_DATA_BUFFER_INTERVALS): STRING_8
		-- concatenated `text_intervals' substrings found in `buffer'
		-- Trims leading and trailing white space and first and last intervals
		do
			Result := output_buffer
			Result.wipe_out
			text_intervals.append_to (buffer, Result)
			Result.right_adjust
		ensure
			is_text_buffer: Result = output_buffer
		end

	buffer_substring (buf: like buffer; lower, upper: INTEGER; keep_ref: BOOLEAN): STRING_8
		-- `lower .. upper' substring of `buffer' placed in `output_buffer'
		require
			valid_range: upper + 1 >= lower and then upper >= lower implies buffer.valid_index (lower) and buffer.valid_index (upper)
		local
			count, i: INTEGER
		do
			Result := output_buffer
			Result.wipe_out
			count := upper - lower + 1
			Result.grow (count)
			if attached Result.area as area_out then
				from i := 0 until i = count loop
					area_out [i] := buf [i + lower]
					i := i + 1
				end
				Result.set_count (i)
			end
			if keep_ref then
				Result := Result.twin
			end
		ensure
			not_keeping_definition: not keep_ref implies Result = output_buffer
		end

	is_null_terminated (text: C_STRING_8): BOOLEAN
		local
			c: CHARACTER
		do
			(text.area + text.count).memory_copy ($c, 1)
			Result := c = '%U'
		end

	filled_attribute_table (attributes: XT_ATTRIBUTE_BUFFER_INTERVALS): like attribute_table
		require
			valid_attributes_count: attributes.is_valid_count
		do
			Result := attribute_table
			Result.wipe_out
			if attached attributes as list and then attached buffer as buf then
				from list.start until list.after loop
					if attached list.item_interval as array then
						if attached name_cache.item (buf, array [0], array [1]) as name then
							Result.put (buffer_substring (buf, array [2], array [3], True), name)
						end
						check
							not_duplicate_name: Result.inserted
						end
					end
					list.forth
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

	shift_buffer_left (a_offset: INTEGER)
			-- Slide all live content left by `a_offset' bytes and adjust
			-- every index that points into `buffer'.
			-- Safe for a forward (left) copy because destination < source.
		require
			positive_offset: a_offset > 0
			offset_leq_ptr: a_offset <= buffer_index
		do
			buffer.copy_data (buffer, a_offset, 0, buffer_end - a_offset)
			buffer_end := buffer_end - a_offset
			buffer_index := buffer_index - a_offset
			position_index := (position_index - a_offset).max (0)
			parse_end_index := (parse_end_index - a_offset).max (0)
		ensure
			buffer_ptr_reduced:  buffer_index  = old buffer_index  - a_offset
			buffer_end_reduced:  buffer_end  = old buffer_end  - a_offset
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

feature {XT_NORMAL_ENCODING} -- Internal structures

	attribute_table: HASH_TABLE [STRING, STRING]
		-- reuseable table of name-value attribute pairs

	attribute_intervals: XT_ATTRIBUTE_BUFFER_INTERVALS
		-- collected attribute name-value pair indices into `buffer'

	buffer: SPECIAL [CHARACTER_8]
		-- Raw byte buffer; do not modify indices outside this class.

	encoding: XT_NORMAL_ENCODING

	output_buffer: STRING_8
		-- used to accumulate text for output

	text_data_intervals: XT_TEXT_DATA_BUFFER_INTERVALS
		-- list of substring intervals `lower .. upper' of `buffer' text

	name_cache: XT_NAME_CACHE
		-- efficient lookup of attribute/

	comment_string: C_STRING_8
		-- shared substring of text `buffer'

end
