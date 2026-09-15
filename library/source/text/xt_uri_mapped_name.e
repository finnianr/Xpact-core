note
	description: "[
		A ${STRING} object that represents a URI name space mapping defined by a `xmlns' declaration.
		If the separator is the pipe character '|', then these are the URI mappings for the document below.
		
			rdf:RDF -> http://www.w3.org/1999/02/22-rdf-syntax-ns#|RDF
			rdf:about -> http://www.w3.org/1999/02/22-rdf-syntax-ns#|about
		
			<!DOCTYPE rdf:RDF [
				 <!ENTITY rdf 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
			]>
			<rdf:RDF xmlns:rdf="&rdf;">
				<rdf:Description rdf:about="&a;#&n;"/>
			</rdf:RDF>
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-14 11:25:00 GMT (Monday 14th September 2026)"
	revision: "1"

class
	XT_URI_MAPPED_NAME

inherit
	STRING
		redefine
			make
		end

create
	make, make_empty, make_from_buffer, make_from_uri

feature {NONE} -- Initialization

	make_from_uri (
		buffer: SPECIAL [CHARACTER]; start_index, end_index, colon_index: INTEGER
		uri: STRING; separator: CHARACTER
	)
		require
			has_colon: colon_index > 0 implies buffer [colon_index] = ':'
		local
			mid_index: INTEGER; s: XT_STRING_8_ROUTINES

		do
			inspect colon_index when 0 then
				mid_index := start_index
			else
				mid_index := colon_index + 1
			end
			make (end_index - mid_index + uri.count + 2)
			append (uri); append_character (separator)
			s.append_area (Current, buffer, mid_index, end_index)

			name_count := end_index - start_index + 1
			create name_area.make_empty (name_count)
			name_area.copy_data (buffer, start_index, 0, name_count)
		ensure
			expected_count: count = uri.count + local_name.count + 1
			starts_with_uri: starts_with (uri) and then item (uri.count + 1) = separator
			ends_with_local_name: ends_with (local_name)
		end

	make_from_buffer (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER)
		local
			s: XT_STRING_8_ROUTINES
		do
			make (end_index - start_index + 1)
			s.append_area (Current, buffer, start_index, end_index)
			name_area := area; name_count := count
		end

	make (n: INTEGER)
		do
			Precursor (n)
			name_area := Default_area
		end

feature -- Access

	name_count: INTEGER

	name_area: SPECIAL [CHARACTER]
		-- characters of normal unresolved name as it occurs in an XML element
		-- Eg. <rdf:Description>

	update (uri: STRING; separator: CHARACTER)
		-- update a forward reference to an xmlns declaration
		local
			colon_index: INTEGER; s: XT_STRING_8_ROUTINES
		do
			colon_index := s.index_of (name_area, ':', 0, name_count - 1)
			resize (count + uri.count + 1)
			wipe_out
			append (uri)
			append_character (separator)
			s.append_area (Current, name_area, colon_index + 1, name_count - 1)
		end

feature {NONE} -- Contract support

	local_name: STRING
		local
			s: STRING
		do
			s := name
			Result := name.substring (s.index_of (':', 1) + 1, s.count)
		end

	name: STRING
		-- normal unresolved name as it occurs in an XML element
		local
			s: XT_STRING_8_ROUTINES
		do
			create Result.make (name_count)
			s.append_area (Result, name_area, 0, name_count - 1)
		end

feature {XT_URI_MAPPED_NAME_CACHE} -- Constants

	Default_area: SPECIAL [CHARACTER]
		once
			create Result.make_empty (0)
		end

end
