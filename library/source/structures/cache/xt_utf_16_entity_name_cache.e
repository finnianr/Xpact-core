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
			hash_index
		end

	XT_UTF_16_NAME_CACHE
		undefine
			buffer_string_8, bucket_index, item, same_string
		end

create
	make
end
