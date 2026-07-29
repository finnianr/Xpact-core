note
	description: "Default instance to satisfy void-safe rules"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-28 20:58:00 GMT (Tuesday 28th July 2026)"
	revision: "1"

class
	XT_DEFAULT_UTF_8_CONVERTER

inherit
	XT_UTF_8_CONVERTER

create
	make

feature -- Initialization

	make
		do
			create buffer_pool.make (0)
			create utf_8_buffer.make_empty (0)
		end

feature -- Measurement

	utf_8_bytes_count (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
		do
		end

feature {NONE} -- Implementation

	buffer_pool: XT_CHARACTER_BUFFER_POOL

	to_utf_8 (source, dest: SPECIAL [CHARACTER]; a_from_index, a_from_end: INTEGER)
			-- Convert source[a_from_index..a_from_end) to UTF-8 in dest [a_to_index .. a_to_end).
			-- Sets consumed_from and written_to.
		do
		end

	to_utf_16 (source: SPECIAL [CHARACTER]; dest: SPECIAL [NATURAL_16]; a_from_index, a_from_end: INTEGER)
			-- Convert source[a_from_index..a_from_end) to UTF-16 in dest.
			-- Sets consumed_from and written_to.
		do
		end
end
