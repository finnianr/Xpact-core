note
	description: "[
		${XT_ATTRIBUTE_LIST} with type of name cache changed to ${XT_URI_MAPPED_NAME_CACHE}
		for name space aware parsing.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-14 17:13:00 GMT (Monday 14th September 2026)"
	revision: "1"

class
	XT_URI_MAPPED_ATTRIBUTE_LIST

inherit
	XT_ATTRIBUTE_LIST
		redefine
			name_cache, name_area, transfer
		end

	XT_STRING_CONSTANTS
		undefine
			copy, is_equal
		end

create
	make

feature -- Access

	name_cache: XT_URI_MAPPED_NAME_CACHE
		-- efficient lookup of attribute/tag name

feature -- Basic operations

	transfer (
		buffer: SPECIAL [CHARACTER_8]; additions: like area; colon_index: INTEGER; entity_list: ARRAYED_LIST [XT_ENTITY_NAME]
	): INTEGER
		local
			start_index: INTEGER
		do
			if is_namespace_declaration (buffer, additions [0], additions [1], colon_index) then
			-- add xmlns declaration to `name_cache'
				start_index := local_part_index (additions [0], colon_index)
				if attached new_substring (buffer, additions [2], additions [3]) as uri then
					inspect colon_index when 0 then
						name_cache.add_uri_default (uri)
					else
						if attached new_substring (buffer, start_index, additions [1]) as name_key then
							name_cache.add_uri (uri, name_key)
							check_forward (name_key, uri)
						end
					end
				end
				additions.wipe_out
			else
				Result := Precursor (buffer, additions, colon_index, entity_list)
			end
		end

feature {NONE} -- Implementation

	check_forward (prefix_name, uri: STRING)
		-- check forward references of new xmlns declaration
		local
			i, i_final: INTEGER; name: XT_URI_MAPPED_NAME
		do
			if attached name_area as l_area then
				from i := 0; i_final := l_area.count until i = i_final loop
					name := l_area [i]
					if name.count >= prefix_name.count + 2 and then name [prefix_name.count + 1] = ':'
						and then name.starts_with (prefix_name)
					then
						name.update (name_cache, uri)
					end
					i := i + 1
				end
			end
		end

	is_namespace_declaration (buffer: SPECIAL [CHARACTER_8]; start_index, end_index, colon_index: INTEGER): BOOLEAN
		do
			inspect buffer [start_index] when 'x' then
				inspect colon_index when 0 then
					Result := same_characters (buffer, start_index, end_index, Xmlns)
				else
					Result := same_characters (buffer, start_index, colon_index - 1, Xmlns)
				end
			else end
		end

feature {NONE} -- Internal attributes

	name_area: SPECIAL [XT_URI_MAPPED_NAME]

end
