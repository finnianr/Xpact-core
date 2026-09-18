note
	description: "${XT_ELEMENT_CONTEXT} with table of default values for attributes"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-25 18:15:00 GMT (Saturday 25th July 2026)"
	revision: "1"

class
	XT_ELEMENT_ATTRIBUTES_CONTEXT

inherit
	XT_ELEMENT_CONTEXT
		rename
			make as make_context
		redefine
			default_attribute_values, has_attributes, update_default_attribute_names, Has_default_values
		end

create
	make

feature {NONE} -- Initialization

	make (a_parse_data: POINTER; a_default_value_table: HASH_TABLE [ARRAYED_LIST [STRING], STRING])
		do
			make_context (a_parse_data)
			create default_value_table.make (a_default_value_table, c_naming_mode (a_parse_data))
		end

feature -- Access

	default_attribute_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE]
		-- unchecked default attribute values for element `name'
		local
			i: INTEGER
		do
			if attached default_value_table [name] as values then
				Result := values
				from i := 0 until i = Result.count loop
					Result [i].uncheck
					i := i + 1
				end
			else
				Result := empty_attribute_values
			end
		end

feature -- Status query

	has_attributes: BOOLEAN
		do
			Result := default_value_table.has (name)
		end

	Has_default_values: BOOLEAN = True

feature {NONE} -- Implementation

	update_default_attribute_names (name_cache: XT_NAME_CACHE)
		-- called from `XT_URI_MAPPED_NAME_CACHE.on_xmlns_declaration_end' to update tag and attribute names
		-- with URI mapping
		local
			i, j, colon_index: INTEGER; tag_name: STRING
		do
			if attached default_value_table as table and then attached table.current_keys as key_array then
				from i := 1 until i > key_array.count loop
					tag_name := key_array [i]
					if attached table [tag_name] as default_attributes then
						from j := 0 until j = default_attributes.count loop
							if attached default_attributes [j] as l_default and then attached l_default.name as l_name then
								colon_index := l_name.index_of (':', 1)
								l_default.set_name (name_cache.attribute_item (l_name.area, 0, l_name.count - 1, colon_index))
							end
							j := j + 1
						end
						colon_index := tag_name.index_of (':', 1)
						table.replace_key (name_cache.item (tag_name.area, 0, tag_name.count - 1, colon_index), tag_name)
					end
					i := i + 1
				end
			end
		end

feature {NONE} -- Internal attributes

	default_value_table: XT_DEFAULT_ATTRIBUTE_VALUE_TABLE
		-- lookup default attribute values by tag name

end
