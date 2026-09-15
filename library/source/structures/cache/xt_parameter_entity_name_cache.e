note
	description: "[
		${XT_NAME_CACHE} for parameter entities declared in document type definition (DTD).
		
		Example:
		
			<!DOCTYPE xsl:stylesheet [
			<!ENTITY % selectors SYSTEM "db-selectors.mod">
			%selectors;
			]>
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-31 14:23:00 GMT (Monday 31st August 2026)"
	revision: "1"

class
	XT_PARAMETER_ENTITY_NAME_CACHE

inherit
	XT_NAME_CACHE
		rename
			item as name_item
		redefine
			new_name, name_item, same_name, Default_bucket
		end

create
	make

feature -- Access

	item (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): like default_name
		do
			Result := name_item (buffer, start_index, end_index, 0)
		end

	Percent: CHARACTER
		once
			Result := '%%'
		end

feature {NONE} -- Implementation

	new_name (buffer: SPECIAL [CHARACTER]; start_index, end_index, colon_index: INTEGER): like default_name
		-- take buffer segment from `start_index' to `end_index' and insert into "&;" at position 2
		do
			create Result.make_from_buffer (buffer, start_index, end_index, percent)
		end

	name_item (buffer: SPECIAL [CHARACTER]; start_index, end_index, colon_index: INTEGER): like default_name
		-- "abc" where `buffer [start_index] = 'a'' and `buffer [end_index] = 'c''
		-- results in "&abc;"
		require else
			ampersand_and_semicolon_excluded: buffer [start_index] /= Percent and buffer [end_index] /= ';'
		do
			Result := Precursor (buffer, start_index, end_index, colon_index)
		end

	same_name (buffer: SPECIAL [CHARACTER]; start_index, end_index, colon_index: INTEGER; name: STRING_8): BOOLEAN
		local
			i, count, i_final: INTEGER
		do
			count := end_index - start_index + 1
			if count = name.count - 2 and then attached name.area as l_area then
				inspect count
					when 1, 2, 3, 4 then
						Result := buffer.same_items (l_area, 1, start_index, count)
				else
				-- check first and last characters
					if buffer [start_index] = l_area [1] and then buffer [end_index] = l_area [name.count - 2] then
						Result := True
						i_final := count - 3
					-- compare middle characters
						from i := 0 until i > i_final loop
							if l_area [i + 2] = buffer [start_index + i + 1] then
								i := i + 1
							else
								i := i_final + 1 -- break
								Result := False
							end
						end
					end
				end
			end
		ensure then
			same_as_inside_name: Result implies name.area.same_items (buffer, start_index, 1, end_index - start_index + 1)
		end

feature {NONE} -- Constants

	Default_bucket: SPECIAL [XT_ENTITY_NAME]
		once ("PROCESS")
			create Result.make_filled (create {like default_name}.make_empty, 1)
		end

end
