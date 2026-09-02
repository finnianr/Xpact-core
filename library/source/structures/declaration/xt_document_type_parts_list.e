note
	description: "${XT_DECLARATION_PARTS_LIST} for `<!DOCTYPE ..>' declaration"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-26 10:16:00 GMT (Wednesday 26th August 2026)"
	revision: "1"

class
	XT_DOCUMENT_TYPE_PARTS_LIST

inherit
	XT_DECLARATION_PARTS_LIST
		redefine
			is_valid
		end

create
	make

feature -- Status query

	is_valid: BOOLEAN
		do
			inspect count
				when 1 then
					Result := not Valid_external_id_list.has (name)

				when 3 then
					if i_th (2) = SYSTEM then
						Result := token_area [2] = Tok_literal
					end

				when 4 then
					if i_th (2) = PUBLIC then
						Result :=  token_area [2] = Tok_literal and token_area [3] = Tok_literal
					end
			else end
		end

feature -- Basic operations

	set_document_type (doctype_identifiers: TUPLE [formal_public, uri: STRING])
		require
			valid_list: is_valid
		local
			second: STRING
		do
			if count >= 3 then
				second := i_th (2)
				if Valid_external_id_list.has (second) then
					doctype_identifiers.formal_public := i_th (3)
					if count = 4 and then second = PUBLIC then
						doctype_identifiers.uri := last
					end
				end
			end
		end

end
