note
	description: "[
		Generate a report like the following from all benchmark log files:

			[x1.86 to eXpat] ns_att_test.xml tag_count: eXpat passes = 14; Xpact-core passes = 26
			[x1.82 to eXpat] recset.xml tag_count: eXpat passes = 17; Xpact-core passes = 31
			..
			[x1.08 to eXpat] recursive-entity-expansion.xml CRC-32-text: eXpat passes = 2803; Xpact-core passes = 3016
			[x1.04 to eXpat] nes96.xml CRC-32-text: eXpat passes = 210; Xpact-core passes = 218

			Average performance: x1.424 to eXpat
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-25 07:50:00 GMT (Saturday 25th July 2026)"
	revision: "1"

class
	BENCHMARK_SORTER

inherit
	XT_STRING_ROUTINES_I

create
	make

feature {NONE} -- Initialization

	make (a_dir_path: PATH)
		local
			find_results: XT_COMMAND_OUTPUT_FILE
		do
			dir_path := a_dir_path
			create log_list.make (100)
			create find_results.make_with_output (Find_template, << a_dir_path >>)
			find_results.append_lines_to (log_list)
		end

feature -- Basic operations

	execute
		local
			path: PATH; log_tail: XT_COMMAND_OUTPUT_FILE; index: INTEGER
			metric_lines: ARRAYED_LIST [STRING]; array: SORTABLE_ARRAY [STRING]
			report_file: PLAIN_TEXT_FILE; report_path: PATH; relative_performance: DOUBLE
		do
			create metric_lines.make (log_list.count)

			across log_list as log_path loop
				create path.make_from_string (log_path)
				if attached path.components as steps
					and then attached steps [steps.count] as log_name
					and then attached steps [steps.count - 1] as name
					and then attached log_name.name.split ('.') as extension_list
					and then attached extension_list [extension_list.count - 1].to_string_8 as test_name
				then
					test_name.prepend_character (' ')

					create log_tail.make_with_output (Tail_template, << log_path >>)
					if log_tail.return_code = 0 and then attached log_tail.first_line as line then
						index := line.index_of (':', 1)
						if index > 0 then
							line.insert_string (test_name, index)
							index := line.last_index_of ('(', line.count)
							if index > 0 and then attached line.substring (index, line.count) as metric then
								line.remove_tail (metric.count + 1)
								metric.remove_head (1); metric.remove_tail (1)
								metric_lines.extend (substitute (Metric_template, << metric, line >>))
							end
						end
						log_tail.cleanup
					end
				end
			end
			create array.make_from_array (metric_lines.to_array)
			array.sort
			report_path := dir_path.extended ("benchmark-report.txt")
			create report_file.make_with_path (report_path)
			if attached report_file as f and then attached {ARRAY [PLAIN_TEXT_FILE]} << f, IO.Output >> as output_list then
				f.open_write
				across metric_lines.new_cursor.reversed as line loop
					across output_list as output loop
						output.put_string (line)
						output.put_new_line
					end
					index := line.index_of (' ', 1)
					if index > 0 and then attached line.substring (3, index - 1) as number then
						relative_performance := relative_performance + number.to_double
					end
				end
				relative_performance := relative_performance / metric_lines.count
				if attached relative_performance.out.substring (1, 5) as number
					and then attached ("Average performance: x" + number + " to eXpat") as average_line
				then
					across output_list as output loop
						output.put_new_line
						output.put_string (average_line)
						output.put_new_line
					end
				end
				f.close
			end
		end

feature {NONE} -- Internal attributes

	log_list: ARRAYED_LIST [STRING]

	dir_path: PATH

feature {NONE} -- Constants

	Find_template: STRING = "find %S -type f -name '*.log'"

	Tail_template: STRING = "tail -n 1 '%S'"

	Metric_template: STRING = "[%S] %S"

end
