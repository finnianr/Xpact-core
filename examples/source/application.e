note
	description: "[
		**Xpact-core example program**
	
		Usage:
			xpact_example <operation> [-chunk_size <value>] [-duration <duration-window-ms>] <XML-file-path>
			
		Valid operations: {-print, -count_tags}

		**-print** Reads from specified XML path and prints each XML event to standard output via XT_XML_PRINTER.

		**-count_tags** Reads from specified XML path and compiles a table of tag occurrence frequency.
		
		**-test** Peforms tests on various classes developed for the Xpact-core project. The name of the test
		can be specified as an argument

	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 18:21:11 GMT (Saturday 20th June 2026)"
	revision: "1"

class APPLICATION

inherit
	XT_PARSE_CONSTANTS

	PARSE_EVENT_CONSTANTS

	ARGUMENTS_32
		export
			{NONE} all
		end

create make

feature {NONE} -- Initialisation

	make
		local
			file_path: PATH
		do
			IO.put_string ("Program: Xpact-core XML parser (Eiffel)")
			IO.put_new_line
			create file_path.make_empty
			if argument_count >= 2 then
				if attached new_argument_8 (0, Option.test) as name and then name.count > 0 then
					do_tests (name)

				elseif attached new_parser as parser and then attached argument (argument_count) as path_arg then
					create file_path.make_from_string (path_arg)
					do_parsing (parser, file_path, new_integer_argument (Option.chunk_size, 0))

				elseif invalid_event_type then
					put_parse_event_error
				else
					put_usage
				end
			else
				put_usage
			end
		end

feature {NONE} -- Factory

	new_argument_8 (index: INTEGER; a_option: detachable STRING): STRING
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
			else
				create Result.make_empty
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

	new_parser: detachable XT_XML_PARSER_BASE
		local
			crc_32_generator: CRC_32_GENERATOR
		do
			if index_of_word_option (Option.count_tags) > 0 then
				create {TAG_COUNTER} Result.make

			elseif index_of_word_option (Option.print_) > 0 then
				create {XML_PRINTER} Result.make

			else
				if attached new_argument_8 (0, Option.crc_32) as data_type then
					if Parse_event_types.has_key (data_type) then
						create crc_32_generator.make (Parse_event_types.found_item, data_type)
						if index_of_word_option (Option.trace) > 0 then
							crc_32_generator.enable_trace
						end
						Result := crc_32_generator
					else
						invalid_event_type := True
					end
				end
			end
		end

feature {NONE} -- Implementation

	do_parsing (parser: XT_XML_PARSER_BASE; file_path: PATH; chunk_size: INTEGER)
		local
			file: PLAIN_TEXT_FILE; time_start: TIME; duration: INTEGER
		do
			create file.make_with_path (file_path)

			if file.exists then
				IO.put_string ("Parsing: " + file_path.out)
				IO.put_new_line

				create time_start.make_now -- start timer
				parse_status := parser.parse_file (file_path, chunk_size, True)
				inspect parse_status
					when Status_error then
						IO.put_string ("Parse error code: " + parser.error_code.out)

					when Status_unreadable then
						IO.put_string ("Cannot read: " + file_path.out)
						IO.put_new_line
				else
					if attached {XT_EXPAT_COMPARABLE} parser as ec then
						duration := new_integer_argument (Option.duration, 0)
						ec.print_stats
						if attached ec.new_benchmark (file_path, time_start, duration, chunk_size) as benchmark then
							benchmark.execute
							if index_of_word_option (Option.compare_to_expat) > 0 then
								benchmark.try_compare_to_expat
							end
						end
					end
				end
			else
				IO.put_string ("File not found: " + file_path.out + "%N")
			end
		end

	do_tests (name: STRING)
		local
			test_set: XT_TEST_SET
		do
			create test_set.make
			test_set.execute (name)
		end

	compile: TUPLE [XT_ASCII_SCANNER, XT_LATIN_1_SCANNER, XP_EXPAT_CALLBACK_HANDLER] --
		do
			create Result
		end

	put_parse_event_error
		do
			IO.put_string ("ERROR: Invalid parse event type for CRC-32 scan")
			IO.put_new_line
			IO.put_string ("Must be one of: {")
			across Parse_event_types.current_keys as type loop
				if not @ type.is_first then
					IO.put_string (", ")
				end
				IO.put_string (type)
			end
			IO.put_character ('}')
			IO.put_new_line
		end

	put_usage
		do
			IO.put_string (
				"Usage: xml_reader <operation> [-chunk_size <value>] [-duration <duration-window-ms>] <XML-file-path>"
			)
			IO.put_string ("Valid operations: {-count_tags, -print}")
			IO.put_string ("OPTIONAL: -chunk_size. Defaults to: 4096")
			IO.put_string ("OPTIONAL: -duration. Defaults to: 500")
			IO.put_new_line
		end

feature {NONE} -- Internal attributes

	parse_status: INTEGER

	invalid_event_type: BOOLEAN

feature {NONE} -- Constants

	Option: TUPLE [compare_to_expat, chunk_size, count_tags, crc_32, duration, print_, test, trace: STRING]
		once
			create Result
			across ("compare_to_expat, chunk_size, count_tags, crc_32, duration, print, test, trace").split (',') as word loop
				word.left_adjust
				Result.put_reference (word, @ word.cursor_index)
			end
		end

end
