note
	description: "Pool of reusable ${SPECIAL [CHARACTER_8]} buffers sorted by capacity"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-06-28 6:31:14 GMT (Sunday 28th June 2026)"
	revision: "1"

class
	XT_CHARACTER_BUFFER_POOL

inherit
	XT_SORTED_BUFFER_POOL [SPECIAL [CHARACTER_8]]

create
	make

feature {NONE} -- Implementation

	capacity_of (buffer: like item): INTEGER
		do
			Result := buffer.capacity
		end

	new_buffer (size: INTEGER): like item
		do
			create Result.make_empty (size)
		end

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (n)
		end

	size_plus (size: INTEGER): INTEGER
		-- allow one extra for NULL terminator
		do
			Result := size + 1
		end

feature {NONE} -- Constants

	Empty_buffer: SPECIAL [CHARACTER_8]
		once
			create Result.make_empty (0)
		end

end
