note
	description: "[
		Abstraction for scanner that gathers document information and is capable of being
		benchmarked against and eXpat program
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-06-29 6:31:14 GMT (Monday 29th June 2026)"
	revision: "1"

deferred class
	XT_EXPAT_COMPARABLE_PARSER

feature -- Access

	checksum: NATURAL
		-- CRC-32/ISO-HDLC checksum
		do
		end

feature -- Factory

	new_benchmark (a_file_path: PATH; a_time_start: TIME; a_duration_ms, a_chunk_size: INTEGER): XT_BENCHMARK_COMPARISON
		deferred
		end

feature -- Basic operations

	parse_file (file_path: PATH; chunk_size: INTEGER; collection_off: BOOLEAN)
		deferred
		end

	print_stats
		deferred
		end

	reset
		deferred
		end

end
