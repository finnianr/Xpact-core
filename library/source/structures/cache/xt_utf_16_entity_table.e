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
			s: XT_STRING_ROUTINES
		do
			Result := s.ascii_to_utf_16 (key)
		end

end
