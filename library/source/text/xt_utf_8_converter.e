note
	description: "Interface for doing conversion to UTF-8 encoded character arrays"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-28 20:36:00 GMT (Tuesday 28th July 2026)"
	revision: "1"

deferred class
	XT_UTF_8_CONVERTER

inherit
	XT_STRING_ROUTINES_I
		export
			{XT_XML_PARSER_BASE, XT_NAME_CACHE} all
		end

feature -- UTF-8 Conversion

	utf_8_converted (
		buf: SPECIAL [CHARACTER_8]; start_index, end_index, byte_count: INTEGER; a_pool: detachable like buffer_pool

	): SPECIAL [CHARACTER]
		-- UTF-8 conversion using recylable character buffer arrays
		require
			correct_byte_count: utf_8_bytes_count (buf, start_index, end_index) = byte_count
		do
			if attached a_pool as pool then
				Result := pool.borrow_item (byte_count)
			else
				Result := utf_8_buffer
			end
			Result.wipe_out
			if byte_count > Result.capacity then
				create Result.make_empty (byte_count)
				utf_8_buffer := Result
			end
			to_utf_8 (buf, Result, start_index, end_index)
		ensure
			correct_byte_count: byte_count = Result.count
		end

	as_utf_8 (source: STRING; keep_ref: BOOLEAN): STRING
		local
			utf_8_count: INTEGER
		do
			Result := Output_buffer
			Result.wipe_out
			utf_8_count := utf_8_bytes_count (source.area, 0, source.count - 1)
			Result.grow (utf_8_count)
			Result.area.wipe_out
			to_utf_8 (source.area, Result.area, 0, source.count - 1)
			Result.area.extend ('%U')
			Result.set_count (utf_8_count)
			if keep_ref then
				Result := Result.twin
			end
		end

feature -- Measurement

	utf_8_bytes_count (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
			-- Number of bytes necessary to encode in UTF-8 `s.substring (start_index, end_index)'.
			-- Note that this feature can be used for both escaped and non-escaped string.
			-- In the case of escaped strings, the result will be possibly higher than really needed.
			-- It does not include the terminating null character.
		require
			end_index_big_enough: start_index <= end_index + 1
			valid_start_index: buf.valid_index (start_index)
			valid_end_index: buf.valid_index (end_index)
		deferred
		end

feature {NONE} -- Deferred

	buffer_pool: XT_CHARACTER_BUFFER_POOL
		deferred
		end

	to_utf_8 (source, dest: SPECIAL [CHARACTER]; a_from_index, a_from_end: INTEGER)
			-- Convert source[a_from_index..a_from_end) to UTF-8 in dest [a_to_index .. a_to_end).
			-- Sets consumed_from and written_to.
		deferred
		end

	to_utf_16 (source: SPECIAL [CHARACTER]; dest: SPECIAL [NATURAL_16]; a_from_index, a_from_end: INTEGER)
			-- Convert source[a_from_index..a_from_end) to UTF-16 in dest.
			-- Sets consumed_from and written_to.
		deferred
		end

feature {NONE} -- Internal attributes

	utf_8_buffer: SPECIAL [CHARACTER_8]

end
