note
	description: "Benchmark ${CRC_32_GENERATOR} against eXpat C program `xml_crc_32'"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-16 17:10:00 GMT (Thursday 15th July 2026)"
	revision: "1"

class
	CRC_32_BENCHMARK

inherit
	XT_BENCHMARK_COMPARISON
		redefine
			make_default, new_command
		end

	PARSE_EVENT_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make_default
		do
			Precursor
			data_type := Tok_tag
		end

feature -- Element change

	set_data_type (a_data_type: INTEGER)
		do
			data_type := a_data_type
		end

feature {NONE} -- Factory

	new_command (template, temp_path: STRING): STRING
		do
			Result := Precursor (template, temp_path)
			Result.replace_substring_all ("$type", new_type_name)
		end

	new_type_name: STRING
		local
			done: BOOLEAN
		do
			create Result.make_empty
			across Parse_event_types as type until done loop
				if type ~ data_type then
					Result := @ type.key
					done := True
				end
			end
		end

feature {NONE} -- Internal attributes

	data_type: INTEGER

feature {NONE} -- Constants

	Command_template: STRING = "xml_crc_32 -type $type -duration $duration $path > $temp_path"

	Log_name_template: STRING
		once
			create Result.make_from_string ("Xpact VS eXpat.CRC-32-%S.log")
		end

end
