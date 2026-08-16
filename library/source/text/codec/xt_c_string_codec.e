note
	description: "Managed pointer that can write UTF-8 encoded characters into ${SPECIAL [CHARACTER]} array"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-30 07:48:00 GMT (Thursday 30th July 2026)"
	revision: "1"

deferred class
	XT_C_STRING_CODEC

feature -- Initialization

	make_shared (a_ptr: POINTER; n: INTEGER)
		deferred
		end

feature -- Access

	area: POINTER
		deferred
		end

	last_index: INTEGER

feature -- Status query

	is_utf_8: BOOLEAN
		do
		end

	not_well_formed: BOOLEAN
		do
		end

	pending_CR: BOOLEAN
		-- `True' if previous content ended with '%R'

feature -- Measurement

	character_count: INTEGER
		do
			Result := count
		end

	count: INTEGER
		deferred
		end

	utf_8_copied_count: INTEGER

feature -- Element change

	reset
		do
		end

feature -- Basic operations

	copy_as_utf_8 (dest: SPECIAL [CHARACTER]; dest_index, n: INTEGER)
		require
			big_enough: dest.valid_index (dest_index + n - 1)
		deferred
		end

	remove_head (n: INTEGER)
		require
			n_less_than_or_equal: n <= count
		deferred
		end

end
