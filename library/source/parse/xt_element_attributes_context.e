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
			default_attribute_values, has_attributes, Has_default_values
		end

create
	make

feature {NONE} -- Initialization

	make (a_section_flags: SPECIAL [BOOLEAN]; a_default_value_table: HASH_TABLE [ARRAYED_LIST [STRING], STRING])
		require
			even_number_of_name_value_pairs:
				across a_default_value_table as name_value_list all
					name_value_list.count.integer_remainder (2) = 0
				end
		local
			attribute_array: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE]; i: INTEGER
		do
			make_context (a_section_flags)
			create default_value_table.make (a_default_value_table.count)
			if attached a_default_value_table as table then
				from table.start until table.after loop
					if attached table.item_for_iteration as name_value_list then
						create attribute_array.make_empty (name_value_list.count // 2)
						from i := 1 until i > name_value_list.count loop
							if name_value_list.valid_index (i + 1) then
								attribute_array.extend (create {XT_DEFAULT_ATTRIBUTE_VALUE}.make (name_value_list [i], name_value_list [i + 1]))
							end
							i := i + 2
						end
						default_value_table.extend (attribute_array, table.key_for_iteration)
					end
					table.forth
				end
			end
		end

feature -- Access

	default_attribute_values: SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE]
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

feature {NONE} -- Internal attributes

	default_value_table: HASH_TABLE [SPECIAL [XT_DEFAULT_ATTRIBUTE_VALUE], STRING]

end
