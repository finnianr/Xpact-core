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

feature -- Access

	formal_public: detachable STRING
		-- 1st literal string after PUBLIC
		-- <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
		do
			if external_id_list.count > 0 then
				Result := external_id_list [0]
			end
		end

	uri: detachable STRING
		-- 2nd literal string after PUBLIC
		-- <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
		do
			if external_id_list.count = 2 then
				Result := external_id_list [1]
			end
		end

feature -- Status query

	is_valid: BOOLEAN
		do
			if count = 1 then
				if has_system_id then
					Result := external_id_list.count = 1

				elseif has_public_id then
					Result := external_id_list.count = 2

				else
					Result := True
				end
			end
		end

end
