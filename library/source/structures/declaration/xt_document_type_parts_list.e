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

create
	make

feature -- Status query

	is_valid: BOOLEAN
		do
			Result := count >= 2
		end

feature -- Basic operations

	set_document_type (formal_public_identifier, DTD_uri: STRING)
		local
			second: STRING
		do
			if count >= 3 then
				second := i_th (2)
				if Valid_external_id_list.has (second) then
					formal_public_identifier.share (i_th (3))
					if count = 4 and then second = PUBLIC then
						DTD_uri.share (last)
					end
				end
			end
		end

feature {NONE} -- Implementation

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (create {like name_cache}.make)
		end

end
