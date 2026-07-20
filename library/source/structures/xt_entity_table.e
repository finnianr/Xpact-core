note
	description: "Table of entities defined in DOCTYPE and character references"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-15 05:10:00 GMT (Wednesday 15th July 2026)"
	revision: "1"

class
	XT_ENTITY_TABLE

inherit
	HASH_TABLE [STRING, STRING]
		rename
			item as table_item
		export
			{NONE} all
			{ANY} put, inserted
		redefine
			make
		end

	XT_STRING_ROUTINES_I
		rename
			Output_buffer as Shared_output_buffer
		undefine
			copy, is_equal
		end

	XT_STRING_CONSTANTS
		rename
			Entity as Entity_uppercase
		undefine
			copy, is_equal
		end

create
	make

feature -- Initialization

	make (n: INTEGER)
		local
			entity: STRING
		do
			Precursor (n)
			create substring.make_empty
			create output_buffer.make_empty
			across Predefined_entities as id loop
				entity := "&;"
				entity.insert_string (id.to_string, 2)
				extend (Predefined_entity_characters [@ id.cursor_index].out, entity)
			end
			set_no_status
		end

feature -- Access

	item (key: STRING): detachable STRING
		require
			valid_length: key.count >= 3
		local
			code: INTEGER
		do
			inspect key [2]
				when '#' then
					if attached table_item (key) as value then
						Result := value
					else
						code := char_ref_number (key.area, 0, key.count - 1)
						if attached utf_8_encoded (code) as l_area then
							Result := new_substring (l_area, 0, l_area.count - 1)
							extend (Result, key)
						end
					end
			else
				if attached table_item (key) as value then
					Result := value
				end
			end
		end

	expanded_value (entity_list: LIST [STRING]; value: STRING; keep_ref: BOOLEAN): STRING
		local
			entity_index, start_index: INTEGER
		do
			Result := output_buffer; Result.wipe_out
			start_index := 1
			across entity_list as entity loop
				entity_index := value.substring_index (entity, start_index)
				if entity_index > 0 then
					Result.append_substring (value, start_index, entity_index - 1)
					if attached item (entity) as entity_value then
						Result.append (entity_value)
					else
						Result.append (entity)
					end
					start_index := entity_index + entity.count
				end
			end
			if start_index <= value.count then
				Result.append_substring (value, start_index, value.count)
			end
			if keep_ref then
				Result := Result.twin
			end
		end

feature -- Basic operations

	mix_in_values_to_crc_32 (
		checksum: EL_CRC_32_DIGEST; buffer: SPECIAL [CHARACTER_8]; entity_list: LIST [STRING]
		lower_index, upper_index: INTEGER
	)
		-- expand entities defined in DOCTYPE for attribute value between `lower_index' and `upper_index'
		local
			amp_index, start_index: INTEGER; done: BOOLEAN
		do
			if attached substring as value then
				value.make_shared (buffer.item_address (lower_index), upper_index - lower_index + 1)
				from entity_list.start; start_index := 1; amp_index := 1; done := False until done loop
					amp_index := value.index_of ('&', start_index)
					if amp_index > 0 then
						checksum.add_characters (buffer, lower_index + start_index - 1, lower_index + amp_index - 2)
						if entity_list.after then
							checksum.add_characters (buffer, lower_index + amp_index - 1, upper_index)
							done := True

						elseif value.has_substring_at (entity_list.item, amp_index) then
							if attached item (entity_list.item) as entity_value then
								checksum.add_string (entity_value)
							end
							start_index := amp_index + entity_list.item.count
							entity_list.forth
						else
							start_index := amp_index + 1
						end
					else
						checksum.add_characters (buffer, lower_index + start_index - 1, upper_index)
						done := True
					end
				end
			end
		end

feature {NONE} -- Internal attributes

	output_buffer: STRING_8

	substring: C_STRING_8

end
