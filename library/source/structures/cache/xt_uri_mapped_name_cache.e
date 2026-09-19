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
			attribute_item, make, name_area, name_count, new_name, on_pop, on_xmlns_declaration_end,
			reset, transfer, valid_tag_name_count, Default_bucket
		end

	XT_STRING_CONSTANTS; XT_NAMING_MODE_CONSTANTS; XT_PARSE_ERROR_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make
		do
			Precursor
			create uri_table.make (11); put_xml_uri
			create string_pool.make (20)
			create element_uri_table.make (5)
			create xmlns_scope_pool.make (5)
			create xmlns_scope_stack.make (5)
			create xmlns_scope_table.make (3)

			separator := Default_separator; naming_mode := NM_uri_SEP_localname
		end

feature -- Access

	separator: CHARACTER

	naming_mode: INTEGER

	attribute_item (buffer: SPECIAL [CHARACTER]; start_index, end_index, colon_index: INTEGER): like default_name
		do
			Result := item (buffer, start_index, end_index, colon_index).as_attribute
		end

feature -- Basic operations

	reset
		do
			Precursor
			uri_table.wipe_out; put_xml_uri
			xmlns_scope_stack.wipe_out
			xmlns_scope_table.wipe_out
			element_uri_table.wipe_out
			depth := 0
		end

	transfer (
		buffer: SPECIAL [CHARACTER_8]; additions: SPECIAL [INTEGER]; colon_index: INTEGER
		attribute_list: XT_ATTRIBUTE_LIST; entity_list: ARRAYED_LIST [XT_ENTITY_NAME]
	): INTEGER
		-- add xmlns declaration
		local
			start_index: INTEGER; expanded_uri, uri, name_key: STRING
		do
			start_index := local_part_index (additions [0], colon_index)
			if entity_list.count > 0 and then attached attribute_list.entity_table as entity_table then
				expanded_uri := entity_table.expanded_value (buffer, additions [2], additions [3], entity_list.area, False, False)
				if entity_table.undefined_entity_found and then not attribute_list.permit_undefined_entities then
					Result := Error_undefined_entity; uri := Empty_string
				else
					uri := new_recyleable (expanded_uri.area, 0, expanded_uri.count - 1)
				end
			else
				uri := new_recyleable (buffer, additions [2], additions [3])
			end
			check
				uri_not_shared_buffer: uri /= Output_buffer
			end
			if uri /= Empty_string then
				inspect colon_index when 0 then
					name_key := Default_uri_key
				else
					name_key := new_recyleable (buffer, start_index, additions [1])
				end
				element_uri_table.put (uri, name_key)
			end
			additions.wipe_out; entity_list.wipe_out
		end

feature -- Element change

	put_uri (uri, name_key: STRING)
		-- add namespace URI (for testing purposes only)
		do
			uri_table.put (uri, name_key)
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
			if element_context.depth + 1 = depth and then attached xmlns_scope_stack as stack
				and then stack.count > 0 and then attached stack.item as xmlns_scope
			then
				bucket_area := xmlns_scope.bucket_area
				uri_table := xmlns_scope.uri_table
				depth := xmlns_scope.element_depth
				xmlns_scope_pool.put (stack.item) -- recyle item
				stack.remove
			end
		end

	on_xmlns_declaration_end (
		buffer: SPECIAL [CHARACTER_8]; tag_name_lower, tag_name_upper: INTEGER
		element_context: XT_ELEMENT_CONTEXT; attribute_list: XT_ATTRIBUTE_LIST
	)
		-- notification after reading list of attributes containing xmlns declaration
		local
			xmlns_scope: like new_xmlns_scope; nested_scope, recycle_table_strings: BOOLEAN
			scope_key: like scope_table_key
		do
			inspect element_context.depth when 0 then
				xmlns_scope := new_xmlns_scope -- gets recycled
			else
				scope_key := scope_table_key (buffer, tag_name_lower, tag_name_upper)
				nested_scope := True
				if attached xmlns_scope_table [scope_key] as scope then
				-- reuse a scope that was already created in an identical previous element
					xmlns_scope := scope
					recycle_table_strings := True
				else
					xmlns_scope := new_xmlns_scope
					xmlns_scope.uri_table := uri_table.twin -- take a copy of parent scope for shadowing
					xmlns_scope.bucket_area := create {like bucket_area}.make_filled (Default_bucket, Size)
					scope_key := scope_key.twin
					check
						not_shared_buffer: scope_key /= empty_buffer
					end
					xmlns_scope_table [scope_key] := xmlns_scope -- save scope for possible reuse in later element
				end
			end
			if attached element_uri_table as table and then attached xmlns_scope.uri_table as l_uri_table then
				from table.start until table.after loop
					l_uri_table [table.key_for_iteration] := table.item_for_iteration
					table.forth
				end
			end
			if nested_scope then
				xmlns_scope_stack.put (new_xmlns_scope) -- save current scope
				depth := element_context.depth + 1 -- plus 1 because element not yet processed
				xmlns_scope.element_depth := depth
				uri_table := xmlns_scope.uri_table
				bucket_area := xmlns_scope.bucket_area
			else
				xmlns_scope_pool.put (xmlns_scope) -- recycle
			end
		-- update any forward references to declared xmlns in attribute list
			if attached element_uri_table as table then
				from table.start until table.after loop
					attribute_list.check_forward (table.key_for_iteration, table.item_for_iteration)
					if depth = 0 and then table.key_for_iteration = Default_uri_key then
						element_context.update_default_attribute_names (Current)
					end
					if recycle_table_strings then
						if table.key_for_iteration /= Default_uri_key then
							string_pool.return (table.key_for_iteration)
						end
						string_pool.return (table.item_for_iteration)
					end
					table.forth
				end
			end
			element_uri_table.wipe_out
		end

feature -- Contract support

	valid_tag_name_count (tag_name: like default_name; expected_count: INTEGER): BOOLEAN
		do
			Result := tag_name.name_count = expected_count
		end

feature {NONE} -- Factory

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
				create Result.make_from_uri (buffer, start_index, end_index, colon_index, naming_mode, uri, separator)

			else
				create Result.make_from_buffer (buffer, start_index, end_index, naming_mode)
			end
		end

	new_recyleable (buffer: SPECIAL [CHARACTER_8]; start_index, end_index: INTEGER): STRING_8
		-- substring of `buffer' that can be recycled again without GC when no longer needed
		do
			Result := string_pool.borrow_item (end_index - start_index + 1)
			Result.wipe_out
			append_area (Result, buffer, start_index, end_index)
		end

	new_xmlns_scope: TUPLE [element_depth: INTEGER; uri_table: like uri_table; bucket_area: like bucket_area]
		do
			if attached xmlns_scope_pool as pool then
				if pool.is_empty then
					Result := [depth, uri_table, bucket_area]
				else
					Result := pool.item
					pool.remove
					Result.element_depth := depth; Result.uri_table := uri_table
					Result.bucket_area := bucket_area
				end
			else
				Result := [depth, uri_table, bucket_area]
			end
		ensure
			is_copy_of_current_scope:
				Result.element_depth = depth and Result.uri_table = uri_table and Result.bucket_area = bucket_area
		end

feature {NONE} -- Implementation

	put_xml_uri
		-- put URI "http://www.w3.org/XML/1998/namespace" for reserved name "xml"
		-- Eg. <svg sodipodi:docname="steam_icon_500.svg" xml:space="preserve" .. />
		do
			put_uri ({XT_STRING_CONSTANTS}.Xml_namespace_uri, {XT_STRING_CONSTANTS}.Xml_lower)
		end

	local_part_index (start_index, colon_index: INTEGER): INTEGER
		do
			inspect colon_index when 0 then
				Result := start_index
			else
				Result := colon_index + 1
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

	scope_table_key (buffer: SPECIAL [CHARACTER_8]; tag_name_lower, tag_name_upper: INTEGER): STRING
		-- unique key to search for an existing scope `like area' that can be reused
		-- For example, the declaration from ATOM feed: <div xmlns='http://www.w3.org/1999/xhtml'>
		-- yields this key: "div|<default>|http://www.w3.org/1999/xhtml"
		do
			Result := empty_buffer
			append_area (Result, buffer, tag_name_lower, tag_name_upper) -- tag/element name
			if attached element_uri_table as table then
				from table.start until table.after loop
					Result.extend ('|'); Result.append (table.key_for_iteration)
					Result.extend ('|'); Result.append (table.item_for_iteration)
					table.forth
				end
			end
		end

feature {NONE} -- Internal attributes

	depth: INTEGER
		-- element depth of current shadow scope

	uri_table: HASH_TABLE [STRING, STRING]

	xmlns_scope_table: HASH_TABLE [like new_xmlns_scope, STRING]

	element_uri_table: HASH_TABLE [STRING, STRING]
		-- small buffer table to store xmlns declarations for most recent element

	string_pool: XT_STRING_BUFFER_POOL
		-- recycleable strings

	xmlns_scope_stack: ARRAYED_STACK [like new_xmlns_scope]

	xmlns_scope_pool: ARRAYED_STACK [like new_xmlns_scope]
		-- recycleable tuples created by `new_xmlns_scope'

feature {NONE} -- Constants

	Default_bucket: SPECIAL [XT_URI_MAPPED_NAME]
		once ("PROCESS")
			create Result.make_filled (create {like default_name}.make_empty, 1)
		end

	Default_separator: CHARACTER = '|'

invariant
	depth_same_as_stack_top_depth:
		(xmlns_scope_stack.count > 0 implies xmlns_scope_stack.item.element_depth = depth) or else depth = 0
end
