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
			make, name_area, name_count, new_name, on_pop, reset, transfer, valid_tag_name_count,
			Default_bucket
		end

	XT_STRING_CONSTANTS; XT_NAMING_MODE_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make
		do
			create area.make_filled (Default_bucket, Size)
			create uri_table.make (11); add_xml_uri
			create depth_stack.make (5)
			separator := Default_separator
			naming_mode := NM_uri_SEP_localname
		end

feature -- Access

	separator: CHARACTER

	naming_mode: INTEGER

feature -- Basic operations

	reset
		do
			Precursor
			uri_table.wipe_out; add_xml_uri
			depth_stack.wipe_out
		end

	transfer (
		buffer: SPECIAL [CHARACTER_8]; additions: SPECIAL [INTEGER]; attribute_list: XT_ATTRIBUTE_LIST
		colon_index, element_depth, tag_name_lower, tag_name_upper: INTEGER
	)
		-- add xmlns declaration
		local
			start_index: INTEGER; added: BOOLEAN; l_depth: INTEGER
		do
			start_index := local_part_index (additions [0], colon_index)
			if attached new_substring (buffer, additions [2], additions [3]) as uri then
				inspect colon_index when 0 then
					add_uri_default (uri); added := True
				else
					if attached new_substring (buffer, start_index, additions [1]) as name_key then
						add_uri (uri, name_key); added := True
					-- Update any forward references to this new declaration
						attribute_list.check_forward (name_key, uri)
					end
				end
				if added then
					l_depth := element_depth + 1 -- + 1 because element not yet added
					if l_depth > depth then
						depth := l_depth
						depth_stack.put (l_depth)
					end
				end
			end
			additions.wipe_out
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

	set_naming_mode (a_naming_mode: INTEGER)
		do
			naming_mode := a_naming_mode
		end

	set_naming (parser_data: XT_PARSER_DATA)
		do
			set_naming_mode (parser_data.naming_mode)
			set_separator (parser_data.namespace_separator)
		end

feature -- Event handler

	on_pop (element_context: XT_ELEMENT_CONTEXT)
		-- notification after `element_context.pop' was called
		do
			if element_context.depth + 1 = depth and then attached depth_stack as stack then
				if stack.count > 0 then
					stack.remove
					if stack.is_empty then
						depth := 0
					else
						depth := stack.item
					end
				end
			end
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

	local_part_index (start_index, colon_index: INTEGER): INTEGER
		do
			inspect colon_index when 0 then
				Result := start_index
			else
				Result := colon_index + 1
			end
		end

	new_name (buffer: SPECIAL [CHARACTER]; start_index, end_index, colon_index: INTEGER; is_attribute: BOOLEAN): like default_name
		-- take buffer segment from `start_index' to `end_index' and insert into "&;" at position 2
		local
			name: STRING
		do
			inspect colon_index when 0 then
				name := if is_attribute then Empty_string else Default_uri_key end
			else
				name := empty_buffer
				append_area (name, buffer, start_index, colon_index - 1)
			end
			if name.is_empty then
				create Result.make_from_buffer (buffer, start_index, end_index, NM_prefix_SEP_localname)

			elseif attached uri_table [name] as uri then
				create Result.make_from_uri (buffer, start_index, end_index, colon_index, naming_mode, uri, separator)

			else
				create Result.make_from_buffer (buffer, start_index, end_index, naming_mode)
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

	depth: INTEGER
		-- element depth of current shadow scope

	uri_table: HASH_TABLE [STRING, STRING]

	depth_stack: ARRAYED_STACK [INTEGER]

feature {NONE} -- Constants

	Default_bucket: SPECIAL [XT_URI_MAPPED_NAME]
		once ("PROCESS")
			create Result.make_filled (create {like default_name}.make_empty, 1)
		end

	Default_separator: CHARACTER = '|'

invariant
	depth_same_as_stack_top: (depth_stack.count > 0 implies depth_stack.item = depth) or else depth = 0
end
