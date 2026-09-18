note
	description: "Pool of reusable ${STRING_8} buffers sorted by capacity"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-17 18:29:00 GMT (Thursday 17th September 2026)"
	revision: "1"

class
	XT_STRING_BUFFER_POOL

inherit
	XT_SORTED_BUFFER_POOL [STRING_8]

create
	make

feature {NONE} -- Implementation

	capacity_of (buffer: like item): INTEGER
		do
			Result := buffer.capacity
		end

	new_buffer (size: INTEGER): like item
		do
			create Result.make (size)
		end

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (n)
		end

	size_plus (size: INTEGER): INTEGER
		do
			Result := size
		end

feature {NONE} -- Constants

	Empty_buffer: STRING_8
		once
			create Result.make (0)
		end

end
