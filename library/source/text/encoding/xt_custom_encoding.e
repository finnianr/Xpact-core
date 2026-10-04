note
	description: "Implementation of ${XT_CUSTOM_ENCODING_I} to be filled in by external C client"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-10-02 11:24:00 GMT (Saturday 2nd October 2026)"
	revision: "1"

class
	XT_CUSTOM_ENCODING

inherit
	XT_CUSTOM_ENCODING_I
		redefine
			fill_codes
		end

create
	make

feature -- Element change

	fill_codes
		do
		end

feature {NONE} -- Implementation

	fill_not_identity
		do
		end

end
