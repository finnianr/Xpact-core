note
	description: "Managed pointer that can write UTF-8 encoded characters into ${SPECIAL [CHARACTER]} array"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-30 07:48:00 GMT (Thursday 30th July 2026)"
	revision: "1"

deferred class
	EL_UTF_8_POINTER_CODEC

inherit
	MANAGED_POINTER
		rename
			item as area,
			share_from_pointer as make_shared
		export
			{EL_LATIN_1_C_STRING} area
			{ANY} count
			{STRING_HANDLER} make_shared
			{NONE} all
		end

	STRING_HANDLER
		undefine
			copy, is_equal
		end

	EL_STRING_H_C_API
		undefine
			copy, is_equal
		end

feature -- Access

	character_count: INTEGER
		do
			Result := count
		end

	utf_8_copied_count: INTEGER

	last_index: INTEGER

feature -- Basic operations

	copy_as_utf_8 (dest: SPECIAL [CHARACTER]; dest_index, n: INTEGER)
		require
			big_enough: dest.valid_index (dest_index + n - 1)
		deferred
		end


	remove_head (n: INTEGER)
		require
			n_less_than_or_equal: n <= count
		do
			if is_shared and n <= count then
				area := area + n
				count := count - n
			end
		end

end
