note
	description: "[
		${STRING_8} that has '%T', '%R' or '%N' characters that must be normalized for text or attribute values
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-01 13:05:00 GMT (Saturday 1th August 2026)"
	revision: "1"

class
	XT_ABNORMAL_STRING

inherit
	STRING
		rename
			make as make_sized
		redefine
			new_string
		end

create
	make, make_sized

feature {NONE} -- Initialization

	make (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; scanner: XT_SCANNER_BASE)
		local
			s: XT_STRING_ROUTINES
		do
			make_sized (end_index - start_index + 1)
			newline_or_tab_found := scanner.newline_or_tab_found
			s.append_area (Current, buffer, start_index, end_index)
		end

feature -- Conversion

	to_attribute: STRING
		-- normalized version of `Current' for placing in an attribute value
		-- (XML §3.3.3 attribute-value normalisation: replace %N %T with space)
		local
			s: XT_STRING_ROUTINES
		do
			if attached internal_attribute as l_attribute then
				Result := l_attribute
			else
				create Result.make (count + 1)
				Result.append (Current)
				Result.extend ('"')
				s.normalize_whitespace (Result.area, 0, Result.count - 2)
				internal_attribute := Result
			end
		end

feature -- Status report

	newline_or_tab_found: BOOLEAN

feature {NONE} -- Implementation

	new_string (n: INTEGER): like Current
			-- New instance of current with space for at least `n' characters.
		do
			create Result.make_sized (n)
		end

feature {NONE} -- Internal attributes

	internal_attribute: detachable STRING
end
