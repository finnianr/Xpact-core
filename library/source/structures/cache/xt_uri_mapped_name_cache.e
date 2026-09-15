note
	description: "${XT_NAME_CACHE} that resolves name space identifiers to URI's"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-14 08:27:00 GMT (Monday 14th September 2026)"
	revision: "1"

class
	XT_URI_MAPPED_NAME_CACHE

inherit
	XT_NAME_CACHE
		redefine
			make, name_area, name_count, new_name, reset, valid_tag_name_count,
			Default_bucket
		end

	XT_STRING_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make
		do
			create area.make_filled (Default_bucket, Size)
			create uri_table.make (11); add_xml_uri
			separator := Default_separator
		end

feature -- Access

	separator: CHARACTER

feature -- Basic operations

	reset
		do
			Precursor
			uri_table.wipe_out; add_xml_uri
		end

feature -- Element change

	add_uri (uri, name_key: STRING)
		-- add namespace URI
		do
			uri_table.put (uri, name_key)
		end

	add_uri_default (uri: STRING)
		-- add namespace URI
		do
			uri_table.put (uri, Default_uri_key)
		end

	set_separator (a_separator: CHARACTER)
		do
			separator := a_separator
		end

feature -- Contract support

	valid_tag_name_count (tag_name: like default_name; expected_count: INTEGER): BOOLEAN
		do
			Result := tag_name.name_count = expected_count
		end

feature {XT_PARSING_BUFFERS} -- Implementation

	add_xml_uri
		do
			add_uri ({XT_STRING_CONSTANTS}.Xml_namespace_uri, {XT_STRING_CONSTANTS}.Xml_lower)
		end

	new_name (buffer: SPECIAL [CHARACTER]; start_index, end_index, colon_index: INTEGER): like default_name
		-- take buffer segment from `start_index' to `end_index' and insert into "&;" at position 2
		local
			name: STRING
		do
			inspect colon_index when 0 then
				name := Default_uri_key
			else
				name := empty_buffer
				append_area (name, buffer, start_index, colon_index - 1)
			end
			if attached uri_table [name] as uri then
				create Result.make_from_uri (buffer, start_index, end_index, colon_index, uri, separator)
			else
				create Result.make_from_buffer (buffer, start_index, end_index)
			end
		end

	name_area (name: like default_name): SPECIAL [CHARACTER]
		do
			Result := name.name_area
		end

	name_count (name: like default_name): INTEGER
		do
			Result := name.name_count
		end

feature {NONE} -- Internal attributes

	uri_table: HASH_TABLE [STRING, STRING]

feature {NONE} -- Constants

	Default_bucket: SPECIAL [XT_URI_MAPPED_NAME]
		once ("PROCESS")
			create Result.make_filled (create {like default_name}.make_empty, 1)
		end

	Default_separator: CHARACTER = '|'

end
