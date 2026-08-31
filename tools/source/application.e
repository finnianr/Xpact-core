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

	XT_DATA_TYPES

	FILE_TREE_TESTS_FACTORY

	XT_SHARED_EXECUTION_ENVIRONMENT

create make

feature {NONE} -- Initialization

	make
		do
			if attached new_application_table as app_table then
				if argument_count = 1 and then attached argument (1).to_string_8 as l_option
					and then l_option ~ "-help"
				then
					show_help_menu (app_table)
				elseif argument_count >= 2 and then attached argument (1).to_string_8 as l_option
					and then attached app_table [l_option] as run
				then
					print ("Program " + l_option + ": Xpact-core XML tools (Eiffel)")
					IO.put_new_line
					run (l_option.substring (2, l_option.count))
				else
					show_help_menu (app_table)
				end
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

	new_crc_32_generator (app_option: STRING): detachable XT_CRC_32_GENERATOR
		do
			if attached new_argument_8 (0, app_option) as data_type_arg
				and then attached Data_type_table [data_type_arg] as data_type
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
			dir_path := last_path_argument
			if Environment.directory_exists (dir_path, Void) then
				create sorter.make (dir_path)
				sorter.execute
			else
				put_usage (app_option)
			end
		end

	do_count_tags (app_option: STRING)
		do
			do_parsing (create {TAG_COUNTER}.make, last_path_argument)
		end

	do_corpus_test (app_option: STRING)
		local
			corpus: XML_CORPUS_TESTER; file_path: PATH
		do
			file_path := last_path_argument
			if Environment.file_exists (file_path, IO.Output) then
				create corpus.make
				corpus.parse_file (file_path, 0, True)
			end
		end

	do_crc_32 (app_option: STRING)
		do
			if attached new_crc_32_generator (app_option) as crc_32 then
				do_parsing (crc_32, last_path_argument)
			else
				put_usage (app_option)
			end
		end

	do_expat_compare (app_option: STRING)
		local
			comparison: XT_EXPAT_COMPARISON; file_path: PATH
		do
			file_path := last_path_argument
			if Environment.file_exists (file_path, IO.Output) then
				create comparison.make (file_path, IO.Output)
				comparison.execute
				if comparison.both_agree then
					if comparison.both_failed then
						IO.put_string ("Both failed for same reason OK")
					else
						IO.put_integer (comparison.pass_count)
						IO.put_character ('/')
						IO.put_integer (comparison.pass_count)
						IO.put_string (" tests agree OK")
					end
					IO.put_new_line
				end
			else
				put_usage (app_option)
			end
		end

	do_print (app_option: STRING)
		local
			file_path: PATH
		do
			file_path := last_path_argument
			if Environment.file_exists (file_path, IO.Output) then
				do_parsing (create {XML_PRINTER}.make, file_path)
			else
				put_usage (app_option)
			end
		end

	do_test (app_option: STRING)
		local
			test_set: XT_TEST_SET
		do
			if attached new_argument_8 (0, app_option) as name then
				create test_set.make
				test_set.execute (name)
			else
				put_usage (app_option)
			end
		end

	do_test_files (app_option: STRING)
		local
			tests: FILE_TREE_TESTS; path: PATH; path_exists: BOOLEAN
		do
			path := last_path_argument
			if attached path.entry as entry and then entry.name.starts_with ("*.") then
				path_exists := Environment.directory_exists (path.parent, IO.Output)
			else
				path_exists := Environment.file_exists (path, IO.Output)
			end
			if path_exists then
				tests := new_tests (path, index_of_word_option (Option.keep_logs) > 0)
				tests.execute
			else
				put_usage (app_option)
			end
		end

	do_xml_hunt (app_option: STRING)
		local
			hunter: FILE_SYSTEM_XML_HUNTER; dir_path: PATH
		do
			dir_path := last_path_argument
			if Environment.directory_exists (dir_path, IO.Output) then
				create hunter.make (dir_path, new_integer_argument (Option.resume_at, 0))
				if hunter.valid_driver then
					hunter.execute
				else
					print ("ntfs3 module required for Windows mount")
					IO.put_new_line
				end
			else
				put_usage (app_option)
			end
		end

feature {NONE} -- Factory

	new_application_table: HASH_TABLE [PROCEDURE, STRING]
		do
			create Result.make_from_iterable_tuples (<<
				[agent do_benchmark_sort,	"-benchmark_sort"],
				[agent do_count_tags,		"-count_tags"],
				[agent do_corpus_test,		"-corpus_test"],
				[agent do_crc_32,				"-crc_32"],
				[agent do_expat_compare,	"-expat_compare"],
				[agent do_print,				"-print"],
				[agent do_test,				"-test"],
				[agent do_test_files,		"-test_files"],
				[agent do_xml_hunt,			"-xml_hunt"]
			>>)
		end

	new_usage_table: HASH_TABLE [STRING, STRING]
		local
			usage, word: STRING; s: XT_STRING_8_ROUTINES
		do
			create Result.make (11)
			usage := s.Empty_string
			across new_application_table.current_keys as l_option loop
				word := l_option.split ('_').first; word.remove_head (1)
				if word ~ "benchmark" then
					usage := new_usage_text (l_option, "<benchmark-dir-path>")
				elseif word ~ "crc" then
					usage := new_usage_text (l_option, "<data-type> " + Bench_mark_options +
						"%NOPTIONAL: -trace. Trace all CRC-32 stages step by step for debugging" +
						"%NValid XML data types: " + s.key_set_string (Data_type_table.current_keys, False)
					)
				elseif word ~ "count" then
					usage := new_usage_text (l_option, Bench_mark_options)

				elseif word ~ "corpus" then
					usage := new_usage_text (l_option, "<corpus-xml-config-path>")

				elseif word ~ "expat" then
					usage := new_usage_text (l_option, "<xml-path>")

				elseif word ~ "print" then
					usage := new_usage_text (l_option, "<xml-file-path>")

				elseif l_option ~ ("test_files") then
					usage := new_usage_text (l_option, "[-keep_logs] (<XML-file-path> | <dir-pattern>)" +
						"%N eg. %"~/Documents/*.docx%""
					)

				elseif word ~ ("test") then
					usage := new_usage_text (l_option, "<test-name>")

				elseif word ~ ("xml") then
					usage := new_usage_text (l_option, "[-resume_at <file-count>] <dir-path>")
				else
					usage := new_usage_text (l_option, "<dir-path>")
				end
				Result.extend (usage, l_option)
			end
		end

	new_usage_text (app_option, parameters: STRING): STRING
		do
			Result := Usage_base + app_option + " " + parameters
		end

feature {NONE} -- Implementation

	last_path_argument: PATH
		do
			if index_of_word_option (Option.path_prompt) > 0 then
				print ("Enter a file path: ")
				IO.read_line
				create Result.make_from_string (IO.last_string)
				IO.put_new_line
			else
				create Result.make_from_string (argument (argument_count))
			end
		end

	do_parsing (parser: XT_XML_PARSER_BASE; file_path: PATH)
		local
			file: PLAIN_TEXT_FILE; time_start: TIME; duration: INTEGER
			chunk_size: INTEGER; checksum: NATURAL
		do
			if Environment.file_exists (file_path, IO.Output) then
				chunk_size := new_integer_argument (Option.chunk_size, 0)
				create file.make_with_path (file_path)
				print ("Parsing: " + file_path.utf_8_name)
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

	put_usage (a_option: STRING)
		do
			if attached new_usage_table [a_option] as usage then
				across usage.split ('%N') as line loop
					print (line)
					IO.put_new_line
				end
			end
		end

	show_help_menu (app_table: HASH_TABLE [PROCEDURE, STRING])
		local
			chosen, found: BOOLEAN; n: INTEGER
		do
			print ("HELP MENU")
			IO.put_new_line
			across app_table.current_keys as l_option loop
				IO.put_integer (@ l_option.cursor_index)
				print (". ")
				print (l_option)
				IO.put_new_line
			end
			from until chosen loop
				print ("Enter an option number: ")
				IO.read_line
				IO.put_new_line
				n := IO.last_string.to_integer
				if 0 <= n and n <= app_table.count then
					chosen := True
				else
					IO.put_new_line
				end
			end
			if n > 0 then
				across app_table.current_keys as l_option until found loop
					if @ l_option.cursor_index = n then
						put_usage (l_option)
						found := True
					end
				end
			end
		end

feature {NONE} -- Constants

	Bench_mark_options: STRING = "[
		[-chunk_size <value>] [-duration <duration-window-ms>] <XML-file-path>
		
		OPTIONAL: -chunk_size. Defaults to: 4096
		OPTIONAL: -duration. Defaults to: 500
	]"

	Operation_parameter: STRING = "<operation>"

	Option: TUPLE [compare_to_expat, chunk_size, duration, keep_logs, path_prompt, resume_at, trace: STRING]
		local
			s: XT_STRING_8_ROUTINES
		once
			create Result
			s.fill_tuple (Result, "compare_to_expat, chunk_size, duration, keep_logs, path_prompt, resume_at, trace")
		end

	Usage_base: STRING = "Usage: xml_reader "

end
