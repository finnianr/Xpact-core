note
	description: "Abstraction for ${XT_ENTITY_PARTS_LIST} and ${XT_PARAMETER_ENTITY_PARTS_LIST}"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-09-01 13:45:00 GMT (Tuesday 1st September 2026)"
	revision: "1"

deferred class
	XT_ENTITY_PARTS_I

inherit
	XT_EXTERNALLY_LINKABLE_DECLARATION
		rename
			make as make_external_id,
			wipe_out as wipe_out_external_id
		end

	XT_TOKEN_CONSTANTS

feature -- Status query

	is_parameter: BOOLEAN
		deferred
		end

	is_valid: BOOLEAN
		do
			if external_id_type > 0 and then external_id_list.count = external_id_part_count then
				if count > 1 then
					Result := count = 3 and i_th (2) = NDATA
				else
					Result := True
				end

			elseif count = 2 then
				Result := i_th_token (1) = Tok_name and i_th_token (2) = Tok_literal
			end
		end

feature -- Access

	entity_name: XT_ENTITY_NAME
		-- entity `name' with properties set
		do
			if attached {XT_ENTITY_NAME} name as l_name then
				set_properties (l_name)
				Result := l_name
			else
				Result := Default_entity_name
			end
		end

	name: STRING
		deferred
		end

	notation_name: detachable STRING
		do
			inspect count when 3 then
				Result := if i_th (2) = NDATA then i_th (3) else Empty_string end
			else
			end
		end

	value: detachable STRING
		do
			inspect count when 2 then
				Result := i_th (2)
			else end
		end

feature -- Measurement

	count: INTEGER
			-- Number of items.
		deferred
		end

feature {NONE} -- Deferred

	i_th alias "[]", at alias "@" (i: INTEGER): STRING
		deferred
		end

	i_th_token (i: INTEGER): INTEGER
		deferred
		end

	token_area: SPECIAL [INTEGER]
		deferred
		end

feature {NONE} -- Implementation

	set_properties (a_name: XT_ENTITY_NAME)
		do
			a_name.set_external_id_type (external_id_type)
			a_name.set_public_id (public_id)
			a_name.set_system_id (system_id)
		end

feature {NONE} -- Constants

	Default_entity_name: XT_ENTITY_NAME
		once
			create Result.make_empty
		end

end
