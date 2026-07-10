note
	description: "Compare Xpact performance with equivalent eXpath application"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-09 08:21:00 GMT (Thursday 9th July 2026)"
	revision: "1"

class
	XT_BENCHMARK_COMPARISON

inherit
	XT_STRING_ROUTINES_I

create
	make

feature {NONE} -- Initialization

	make (a_parser: XT_XML_PARSER_BASE; a_file_path: PATH; a_time_start: TIME; a_duration_ms, a_chunk_size: INTEGER)
		do
			parser := a_parser; file_path := a_file_path
			time_start := a_time_start; duration_ms := a_duration_ms; chunk_size := a_chunk_size
			if attached Environ.item (Var_benchmarks_dir) as dir_path then
				create benchmark_dir_path.make_from_string (dir_path)
			else
				create benchmark_dir_path.make_empty
			end
		end

feature -- Access

	benchmark_dir_path: PATH

	parse_status: INTEGER

feature -- Basic operations

	execute
		do
			if duration_ms > 0 then
			-- Do benchmarking
				from pass_count := 1 until elapsed_milliseconds (time_start) > duration_ms loop
					pass_count := pass_count + 1
					parser.reset
					parse_status := parser.parse_file (file_path, chunk_size, True)
				end
				IO.put_string ("Total number of passes in ")
				IO.put_string (duration_ms.out + " ms: " + pass_count.out)
				IO.put_new_line
			end
		end

	try_compare_to_expat
		do
			if benchmark_dir_path.is_empty then
				IO.put_string ("Environment variable " + Var_benchmarks_dir + " is not defined")
				IO.put_new_line
			else
				compare_to_expat
			end
		end

feature {NONE} -- Implementation

	compare_to_expat
		require
			benchmark_dir_defined: not benchmark_dir_path.is_empty
		local
			index_colon, expat_pass_count: INTEGER; time_stamp: DATE_TIME
			expat_output, log_file: PLAIN_TEXT_FILE done: BOOLEAN
			log_path: PATH; command, log_line, xml_file_name: STRING
		do
			create log_line.make_empty

			if attached file_path.entry as base_name then
				xml_file_name := base_name.out
			else
				create xml_file_name.make_empty
			end
			log_path := benchmark_dir_path.extended (substitute (Log_name_template, << xml_file_name >>))
			command := "xml_tag_counter $path -duration $duration > $temp_path"
			command.replace_substring_all ("$path", file_path.out)
			command.replace_substring_all ("$duration", duration_ms.out)
			if attached Environ.Temporary_directory_path as temp_dir
				and then attached temp_dir.extended ("xml_tag_counter.txt") as temp_path
			then
				command.replace_substring_all ("$temp_path", temp_path.out)
				Environ.system (command)
				if Environ.return_code = 0 then
					create expat_output.make_open_read (temp_path.name)
					from  until done loop
						expat_output.read_line
						if expat_output.end_of_file then
							done := true
						elseif attached expat_output.last_string as line then
							IO.put_string (line)
							IO.put_new_line
							if line.starts_with ("Number of passes") then
								index_colon := line.last_index_of (':', line.count)
								expat_pass_count := line.substring (index_colon + 2, line.count).to_integer
								log_line := substitute (Log_template, <<
									xml_file_name, expat_pass_count.out, xpact_pass_count.out,
									relative_performance (expat_pass_count)
								>>)
							end
						end
					end
					expat_output.close; expat_output.delete

					create time_stamp.make_now
					create log_file.make_with_path (log_path)
					if attached log_file as f then
						if not f.exists then
							f.open_write
							f.put_string ("Log of benchmarks for parsing file: " + xml_file_name)
							f.put_new_line
							f.close
						end
						f.open_append
						f.put_new_line
						f.put_string (time_stamp.formatted_out (Date_format))
						f.put_new_line
						f.put_string (log_line)
						f.put_new_line
						f.close
					end
				end
			end
		end

	elapsed_milliseconds (a_time_start: TIME): INTEGER
		local
			time_now: TIME
		do
			create time_now.make_now
			Result := (time_now.relative_duration (a_time_start).fine_seconds_count * 1000).rounded
		end

	relative_performance (expat_pass_count: INTEGER): STRING
		local
			ratio: DOUBLE
		do
			ratio := xpact_pass_count / expat_pass_count
			Result := (ratio * 100).rounded.out
			if ratio < ratio.one then
				Result.prepend ("0.")
			else
				Result.insert_character ('.', 2)
			end
		end

	xpact_pass_count: INTEGER
		do
			Result := pass_count
		end

feature {NONE} -- Internal attributes

	file_path: PATH

	time_start: TIME

	duration_ms: INTEGER

	pass_count: INTEGER

	chunk_size: INTEGER

	parser: XT_XML_PARSER_BASE

feature {NONE} -- Constants

	Date_format: STRING
		once
			Result := "yyyy [0]dd Mmm hh:[0]mi"
		end

	Environ: EXECUTION_ENVIRONMENT
		once
			create Result
		end

	Log_name_template: STRING
		once
			create Result.make_from_string ("Xpact VS expat %S.log")
		end

	Log_template: STRING
		once
			Result := "%S: eXpat passes = %S; Xpact-core passes = %S (x%S to eXpat)"
		end

	Var_benchmarks_dir: STRING = "BENCHMARKS_DIR"
end
