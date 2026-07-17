note
	description: "Benchmark ${TAG_COUNTER} against eXpat C program `xml_tag_counter'"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-16 17:10:00 GMT (Thursday 15th July 2026)"
	revision: "1"

class
	TAG_COUNTER_BENCHMARK

inherit
	XT_BENCHMARK_COMPARISON

create
	make

feature {NONE} -- Factory

	new_type_name: STRING
		do
			Result := "tag_count"
		end

feature {NONE} -- Constants

	Command_template: STRING = "xml_tag_counter $path -duration $duration > $temp_path"

	Log_name_template: STRING
		once
			create Result.make_from_string ("Xpact VS eXpat.%S.log")
		end

end
