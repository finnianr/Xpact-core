note
	description: "[
		${XT_NAME_CACHE} specialized for entity names like: &rdf; &#10; &#x20AC;
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-21 08:44:40 GMT (Tuesday 21th July 2026)"
	revision: "1"

class
	XT_ENTITY_NAME_CACHE

inherit
	XT_NAME_CACHE
		redefine
			buffer_string_8, bucket_index, item, same_string
		end

create
	make

feature -- Access

	item (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): STRING
		-- "abc" where `buffer [start_index] = 'a'' and `buffer [end_index] = 'c''
		-- results in "&abc;"
		require else
			ampersand_and_semicolon_excluded:
				buffer [start_index] /= '&' and buffer [end_index] /= ';'
		do
			Result := Precursor (buffer, start_index, end_index)
		end

feature {XT_PARSING_BUFFERS} -- Implementation

	buffer_string_8 (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): STRING_8
		-- take buffer segment from `start_index' to `end_index' and insert into "&;" at position 2
		local
			count, full_count: INTEGER
		do
			count := end_index - start_index + 1
			full_count := count + 2
			create Result.make_filled ('%U', full_count)

			if attached Result.area as l_area then
				l_area [0] := '&'
				l_area.copy_data (buffer, start_index, 1, count)
				l_area [full_count - 1] := ';'
			end
		end

feature {NONE} -- Implementation

	bucket_index (buffer: SPECIAL [CHARACTER]; a_start_index, a_end_index: INTEGER): INTEGER
		-- very fast well distributed hash with only 3 components
		local
			start_index, end_index: INTEGER
		do
			start_index := a_start_index; end_index := a_end_index
			if buffer [start_index] = '#' then
				start_index := start_index + 1 -- omit '#'
				if end_index - start_index + 1 > 1 and then buffer [start_index] = 'x' then
				-- hexadecimal number
					start_index := start_index + 1 -- omit 'x'
					end_index := end_index - 1 -- omit ';'
				end
			end
			Result := hash_index (buffer, start_index, end_index)
		end

	same_string (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; name: STRING_8): BOOLEAN
		local
			i: INTEGER
		do
			if end_index - start_index + 1 = name.count - 2 and then attached name.area as l_area then
				Result := True
				from i := start_index until i > end_index or not Result loop
					if buffer [i] = l_area [i - start_index + 1] then
						i := i + 1
					else
						Result := False
					end
				end
			end
		end

end
