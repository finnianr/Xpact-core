note
	description: "[
		Parser name handling modes corresponding to eXpat booleans in `struct XML_ParserStruct'
		defined in `xmlparse.c'. 
		
			XML_Bool m_ns;
			XML_Bool m_ns_triplets;
			
		**Relevant functions**
		
			XML_ParserCreate
			XML_ParserCreateNS
			XML_ParserCreateNS + XML_SetReturnNSTriplet

	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-16 07:54:00 GMT (Wednesday 16th September 2026)"
	revision: "1"

class
	XT_NAMING_MODE_CONSTANTS

feature {NONE} -- Constants

	NM_prefix_SEP_localname: INTEGER = 1
		-- XML_ParserCreate

	NM_uri_SEP_localname: INTEGER = 2
		-- XML_ParserCreateNS

	NM_uri_SEP_localname_SEP_prefix: INTEGER = 3
		-- XML_ParserCreateNS + XML_SetReturnNSTriplet

	Valid_naming_modes: INTEGER_INTERVAL
		once
			Result := NM_prefix_SEP_localname |..| NM_uri_SEP_localname_SEP_prefix
		end

end
