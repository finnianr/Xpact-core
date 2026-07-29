note
	description: "${XT_ENTITY_TABLE} with predefined entities expanded to UTF-16"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	XT_UTF_16_ENTITY_TABLE

inherit
	XT_ENTITY_TABLE
		redefine
			encoded_key
		end

create
	make

feature {NONE} -- Implementation

	encoded_key (key: STRING): STRING
		local
			i: INTEGER
		do
			create Result.make_filled ('%U', key.count * 2)
			from i := 1 until i > key.count loop
				Result [(i - 1) * 2 + 1] := key [i]
				i := i + 1
			end
		ensure then
			valid_last: Result [Result.count - 1] = key [key.count]
		end

end
