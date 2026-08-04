note
	description: "[
		**Xpact-core example program**
	
		Usage:
			xpact_example <operation> [-trace] [-chunk_size <value>] [-duration <duration-window-ms>] <XML-file-path>
			
		**Valid operations:**

		**-crc_32** Class: ${CRC_32_GENERATOR}.
		Reads from specified XML path and prints a CRC-32 checksum for output for specified data type.


		**-print** Class: ${XML_PRINTER}.
		Reads from specified XML path and prints each XML event to standard output.

		**-count_tags** Class: ${TAG_COUNTER}
		Reads from specified XML path and compiles a table of tag occurrence frequency.

		**-test** Peforms tests on various classes developed for the Xpact-core project. The name of the test
		can be specified as an argument
		
		**-test_files** Class: ${FILE_TREE_TESTS}
		Compare CRC-32 for tree of XML files against eXpat.
		Usage: xml_reader -test_files <XML-file-path>
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 18:21:11 GMT (Saturday 20th June 2026)"
	revision: "1"

class APPLICATION

inherit
	ARGUMENTS_32
		export
			{NONE} all
		end

	XT_PARSE_CONSTANTS

	PARSE_EVENT_CONSTANTS

	FILE_TREE_TESTS_FACTORY

	XT_SHARED_EXECUTION_ENVIRONMENT

create make

feature {NONE} -- Initialization

	make
		do
			if argument_count >= 2 and then attached new_application_table as app_table
				and then attached argument (1).to_string_8 as l_option
				and then attached app_table [l_option] as run
			then
				IO.put_string ("Program " + l_option + ": Xpact-core XML tools (Eiffel)")
				IO.put_new_line
				run (l_option.substring (2, l_option.count))
			else
				put_usage (Operation_parameter)
			end
		end

feature {NONE} -- Factory

	new_argument_8 (index: INTEGER; a_option: detachable STRING): detachable STRING
		local
			i: INTEGER
		do
			if attached a_option as l_option then
				i := index_of_word_option (l_option)
				if i > 0 then
					i := i + 1
				end
			else
				i := index
			end
			if 0 < i and i <= argument_count then
				Result := argument (i).to_string_8
			end
		end

	new_integer_argument (a_option: STRING; default_value: INTEGER): INTEGER
		do
			if attached new_argument_8 (0, a_option) as str and then str.is_integer then
				Result := str.to_integer_32
			else
				Result := default_value
			end
		end

	new_crc_32_generator (app_option: STRING): detachable CRC_32_GENERATOR
		do
			if attached new_argument_8 (0, app_option) as data_type_arg
				and then attached Parse_data_types [data_type_arg] as data_type
			then
				create Result.make (data_type)
				if index_of_word_option (Option.trace) > 0 then
					Result.enable_trace
				end
			end
		end

feature {NONE} -- Application options

	do_benchmark_sort (app_option: STRING)
		local
			sorter: BENCHMARK_SORTER; dir_path: PATH
		do
			dir_path := path_argument_last
			if Environment.directory_exists (dir_path, Void) then
				create sorter.make (dir_path)
				sorter.execute
			else
				IO.put_string ("Usage: xml_reader -benchmark_sort <benchmark-dir-path>")
				IO.put_new_line
			end
		end

	do_count_tags (app_option: STRING)
		do
			do_parsing (create {TAG_COUNTER}.make, path_argument_last)
		end

	do_corpus_test (app_option: STRING)
		local
			corpus: XML_CORPUS_TESTER; file_path: PATH
		do
			file_path := path_argument_last
			if Environment.file_exists (file_path, IO.Output) then
				create corpus.make
				corpus.parse_file (file_path, 0, True)
			end
		end

	do_crc_32 (app_option: STRING)
		local
			s: XT_STRING_ROUTINES
		do
			if attached new_crc_32_generator (app_option) as crc_32 then
				do_parsing (crc_32, path_argument_last)
			else
				put_usage ("-crc_32 <data-type> [-trace]")
				IO.put_string ("Valid XML data types: " + s.key_set_string (Parse_data_types.current_keys, False))
				IO.put_new_line
			end
		end

	do_print (app_option: STRING)
		local
			file_path: PATH
		do
			file_path := path_argument_last
			if Environment.file_exists (file_path, IO.Output) then
				do_parsing (create {XML_PRINTER}.make, file_path)
			end
		end

	do_test (app_option: STRING)
		local
			test_set: XT_TEST_SET
		do
			if attached new_argument_8 (0, app_option) as name then
				create test_set.make
				test_set.execute (name)
			end
		end

	do_test_files (app_option: STRING)
		local
			tests: FILE_TREE_TESTS; path, dir_path: PATH
		do
			path := path_argument_last
			create dir_path.make_empty
			if attached path.entry as entry and then entry.name.has ('*') then
				if attached path.parent as parent then
					dir_path := parent
				end
			else
				dir_path := path
			end
			if Environment.directory_exists (dir_path, IO.Output) then
				tests := new_tests (path, index_of_word_option (Option.keep_logs) > 0)
				tests.execute
			else
				IO.put_string ("Usage: xml_reader -test_files [-keep_logs] <XML-file-path>")
				IO.put_new_line
			end
		end

feature {NONE} -- Implementation

	path_argument_last: PATH
		do
			create Result.make_from_string (argument (argument_count))
		end

	do_parsing (parser: XT_XML_PARSER_BASE; file_path: PATH)
		local
			file: PLAIN_TEXT_FILE; time_start: TIME; duration: INTEGER
			chunk_size: INTEGER; checksum: NATURAL
		do
			if Environment.file_exists (file_path, IO.Output) then
				chunk_size := new_integer_argument (Option.chunk_size, 0)
				create file.make_with_path (file_path)
				IO.put_string ("Parsing: " + file_path.utf_8_name)
				IO.put_new_line

				create time_start.make_now -- start timer
				parser.parse_file (file_path, chunk_size, True)
				inspect parser.status
					when Status_ok then
						if attached {XT_EXPAT_COMPARABLE_PARSER} parser as comparable then
							duration := new_integer_argument (Option.duration, 0)
							comparable.print_stats
							checksum := comparable.checksum
							if attached comparable.new_benchmark (file_path, time_start, duration, chunk_size) as benchmark then
								benchmark.execute (checksum)
								if index_of_word_option (Option.compare_to_expat) > 0 then
									benchmark.try_compare_to_expat
								end
							end
						end
				else
					parser.put_error (IO.Error, file_path)
				end
			end
		end

	compile: TUPLE [XP_EXPAT_CALLBACK_HANDLER]
		do
			create Result
		end

	new_application_table: HASH_TABLE [PROCEDURE, STRING]
		do
			create Result.make_from_iterable_tuples (<<
				[agent do_benchmark_sort,	"-benchmark_sort"],
				[agent do_count_tags,		"-count_tags"],
				[agent do_corpus_test,		"-corpus_test"],
				[agent do_crc_32,				"-crc_32"],
				[agent do_print,				"-print"],
				[agent do_test,				"-test"],
				[agent do_test_files,		"-test_files"]
			>>)
		end

	put_usage (operation: STRING)
		local
			s: XT_STRING_ROUTINES
		do
			IO.put_string (
				"Usage: xml_reader " + operation + " [-chunk_size <value>] [-duration <duration-window-ms>] <XML-file-path>"
			)
			IO.put_string ("Valid operations: " + s.key_set_string (new_application_table.current_keys, False))
			IO.put_new_line
			IO.put_string ("OPTIONAL: -chunk_size. Defaults to: 4096")
			IO.put_new_line
			IO.put_string ("OPTIONAL: -duration. Defaults to: 500")
			IO.put_new_line
			IO.put_string ("OPTIONAL: -trace. (-crc_32 only) Trace all CRC-32 stages step by step for debugging")
			IO.put_new_line
		end

feature {NONE} -- Constants

	Operation_parameter: STRING = "<operation>"

	Option: TUPLE [compare_to_expat, chunk_size, duration, keep_logs, trace: STRING]
		local
			s: XT_STRING_ROUTINES
		once
			create Result
			s.fill_tuple (Result, "compare_to_expat, chunk_size, duration, keep_logs, trace")
		end

end
