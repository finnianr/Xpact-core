note
	description: "${XT_ENTITY_NAME_CACHE} adapted for UTF-16 LE character sequences"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-29 10:15:00 GMT (Wendsday 29th July 2026)"
	revision: "1"

class
	XT_UTF_16_ENTITY_NAME_CACHE

inherit
	XT_ENTITY_NAME_CACHE
		undefine
			advance, area_count, char_width, copy_characters, hash_index, latin_1_count, offset_by
		redefine
			new_utf_8
		end

	XT_UTF_16_NAME_CACHE
		undefine
			buffer_string_8, bucket_index, item, same_string
		redefine
			new_utf_8
		end

create
	make

feature {NONE} -- Implementation

	new_utf_8 (name: STRING): STRING
		do
			Result := name
		end
end
