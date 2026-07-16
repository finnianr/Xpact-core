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
	XT_EXPAT_COMPARABLE

feature -- Factory

	new_benchmark (a_file_path: PATH; a_time_start: TIME; a_duration_ms, a_chunk_size: INTEGER): XT_BENCHMARK_COMPARISON
		deferred
		end

feature -- Basic operations

	print_stats
		deferred
		end

end
