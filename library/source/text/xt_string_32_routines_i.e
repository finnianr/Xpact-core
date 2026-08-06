note
	description: "Summary description for {XT_STRING_32_ROUTINES_I}."

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-09-05 13:40:00 GMT (Thursday 5th August 2026)"
	revision: "1"

class
	XT_STRING_32_ROUTINES_I

inherit
	XT_SHARED_INDEX_STACK

	STRING_HANDLER

feature {NONE} -- Access

	frozen substitute (template: STRING_32; insertions: ARRAY [STRING_32]): STRING_32
		require
			enough_place_holders: template.occurrences ('%S') = insertions.count
		local
			index, last_index: INTEGER; index_stack: like Shared_index_stack
		do
			Result := template.twin
			index_stack := Shared_index_stack

			last_index := template.last_index_of ('%S', template.count)
			from until index = last_index loop
				index := Result.index_of ('%S', index + 1)
				if index > 0 then
					index_stack.put (index)
				end
			end
			from until index_stack.is_empty loop
				Result.replace_substring (insertions [index_stack.count], index_stack.item, index_stack.item)
				index_stack.remove
			end
		ensure
			empty_stack: Shared_index_stack.is_empty
		end


end
