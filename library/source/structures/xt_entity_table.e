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
	HASH_TABLE [STRING, XT_ENTITY_NAME]
		rename
			empty as table_empty,
			item as table_item,
			put as put_name
		export
			{NONE} all
			{ANY} inserted
		redefine
			make, same_keys
		end

	XT_STRING_8_ROUTINES_I
		rename
			Output_buffer as Shared_output_buffer
		undefine
			copy, is_equal
		end

	XT_STRING_CONSTANTS
		undefine
			copy, is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (n: INTEGER)
		do
			Precursor (n)
			create output_buffer.make_empty
		end

feature -- Status report

	undefined_entity_found: BOOLEAN

feature -- Access

	item (key: XT_ENTITY_NAME): detachable STRING
		-- if `as_attribute_value' is `True' normalize Result for attribute values
		--  (XML §3.3.3 attribute-value normalisation: replace %N %T with space)
		require
			valid_length: key.count >= 3
		local
			code: INTEGER
		do
			inspect key [2] when '#' then
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
				Result := table_item (key)
			end
		end

	inserted_name: detachable XT_ENTITY_NAME

	expanded_value (
		buffer: SPECIAL [CHARACTER_8]; lower_index, upper_index: INTEGER; a_entity: SPECIAL [XT_ENTITY_NAME]
		is_dtd_literal, keep_ref: BOOLEAN
	): STRING
		-- copy of `value' with any entities like &amp; expanded.
		-- `undefined_entity_found' set to true if any were undefined
		local
			amp_index, start_index, i: INTEGER; done, undefined_found: BOOLEAN
		do
			Result := output_buffer; Result.wipe_out
			from i := 0; start_index := lower_index; amp_index := lower_index; done := False until done loop
				amp_index := index_of (buffer, '&', start_index, upper_index)
				if amp_index > -1 then
					append_area (Result, buffer, start_index, amp_index - 1)
					if i = a_entity.count then
						append_area (Result, buffer, amp_index, upper_index)
						done := True

					elseif attached a_entity [i] as name
						and then same_characters (buffer, amp_index, amp_index + name.count - 1, name)
					then
						if is_dtd_literal implies name.is_dtd_expandable then
							if attached item (name) as entity_value then
								Result.append (entity_value)
								if entity_value.same_type (Abnormal_string) then
								-- appended tail requires normalization as per specification
								-- (XML §3.3.3 attribute-value normalisation: replace %N %T with space)
									normalize_whitespace (Result.area, Result.count - entity_value.count, Result.count - 1)
								end
							else
								undefined_found := True
							end
						else
						-- output non expanded-entity for DTD
							Result.append (name)
						end
						start_index := amp_index + name.count
						i := i + 1
					else
						start_index := amp_index + 1
					end
				else
					append_area (Result, buffer, start_index, upper_index)
					done := True
				end
			end
			undefined_entity_found := undefined_found
		end

feature -- Element change

	set_predefined (entity_cache: XT_ENTITY_NAME_CACHE)
		do
			merge (entity_cache.predefined_table)
		end

	put (new: STRING; a_name: STRING)
		local
			l_name: XT_ENTITY_NAME
		do
			if attached {XT_ENTITY_NAME} a_name as name then
				l_name := name
			else
				create l_name.make_shared (a_name)
			end
			put_name (new, l_name)
			inserted_name := if inserted then l_name else Void end
		end

feature {NONE} -- Implementation

	same_keys (a_search_key, a_key: XT_ENTITY_NAME): BOOLEAN
			-- Does `a_search_key' equal to `a_key'?
			--| Default implementation is using ~.
		do
			Result := a_search_key = a_key
		end

feature {NONE} -- Internal attributes

	output_buffer: STRING_8

	Abnormal_string: XT_ABNORMAL_STRING
		once
			create Result.make (0)
		end

end
