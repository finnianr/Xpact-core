note
	description: "Table to count occurrences of a name and list sorted by occurrence count"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-05 12:42:00 GMT (Wednesday 5th August 2026)"
	revision: "1"

class
	XT_NAME_OCCURRENCE_COUNT_TABLE

inherit
	HASH_TABLE [XT_NAME_OCCURRENCE_COUNT, STRING]
		rename
			put as put_item
		end

create
	make

feature -- Access

	sorted_occurrence_list (ascending: BOOLEAN): ARRAYED_LIST [XT_NAME_OCCURRENCE_COUNT]
		local
			array: SORTABLE_ARRAY [XT_NAME_OCCURRENCE_COUNT]
		do
			create Result.make (count)
			if attached linear_representation as count_list then
				create array.make_from_array (count_list.to_array)
				array.sort
				if ascending then
					create Result.make_from_array (array)
				else
					across array.new_cursor.reversed as tag_count loop
						Result.extend (tag_count)
					end
				end
			end
		end

feature -- Measurement

	sum_occurrence_count: INTEGER
		do
			across Current as l_item loop
				Result := Result + l_item.count
			end
		end

feature -- Element change

	put (name: STRING)
		do
			if not has_key (name) then
				put_item (create {XT_NAME_OCCURRENCE_COUNT}.make (name), name)
			end
			if attached found_item as l_item then
				l_item.increment
			end
		end
end
