note
	description: "Test Xpact CRC-32 data type sums against eXpat"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-05 14:26:00 GMT (Wednesday 5th August 2026)"
	revision: "1"

class
	XT_EXPAT_COMPARISON

inherit
	XT_STRING_8_ROUTINES_I

	XT_PARSE_CONSTANTS
		export
			{NONE} all
		end

	XT_PARSE_EVENT_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make (a_file_path: PATH; a_log: PLAIN_TEXT_FILE)
		do
			file_path := a_file_path; log := a_log
			expat_error := Empty_string; package_name := Empty_string
			xpact_error := Empty_string
		end

feature -- Status report

	values_differ: BOOLEAN

	both_failed: BOOLEAN

	both_agree: BOOLEAN
		-- both Xpact and eXpat agree including the case where the document fails to parse
		local
			index_colon: INTEGER
		do
			if both_failed then
				index_colon := expat_error.index_of (':', 1)
				if index_colon > 0 then
					Result := expat_error.same_caseless_characters (xpact_error, 1, xpact_error.count, index_colon + 2)
				end
			elseif pass_count = Parse_data_types.count then
				Result := True
			end
		end

feature -- Measurement

	pass_count: INTEGER

feature -- Element change

	set_package_name (a_package_name: STRING)
		do
			package_name := a_package_name
		end

feature -- Basic operations

	execute
		-- count of data types that pass checksum comparison with eXpat
		-- -1 if both Xpact and eXpat fail to parse invalid document
		local
			crc_32: XT_CRC_32_GENERATOR; description: STRING
		do
			across Parse_data_types as data_type until values_differ or both_failed loop
				create crc_32.make (data_type)
				crc_32.parse_file (file_path, 0, True)
				call_expat_xml_crc_32 (@ data_type.key)
				if crc_32.status /= Status_ok and expat_return_code > 0 then
					both_failed := True
					xpact_error := crc_32.error_description

				elseif crc_32.status = Status_ok then
					if crc_32.checksum.value = expat_checksum then
						pass_count := pass_count + 1
					else
						log_checksums (<< @ data_type.key, crc_32.checksum.value.out, expat_checksum.out >>)
						values_differ := True
					end
				else
					if crc_32.status = Status_error then
						description := crc_32.error_description
					else
						description := crc_32.status_description
					end
					log.put_string (substitute (Error_template, << description, file_path.out >>))
					log.put_new_line; log.put_new_line
					values_differ := True
				end
			end
		end

	put_status (medium: IO_MEDIUM)
		do
			medium.put_string (" OK")
			if both_failed then
				medium.put_string (" (Both failed)")
				medium.put_new_line
				medium.put_string ("   "); medium.put_string (expat_error)
			end
		end

feature {NONE} -- Implementation

	call_expat_xml_crc_32 (type: STRING)
		-- call C program xml_crc_32 setting `expat_return_code' and `expat_checksum'
		local
			output_file: XT_COMMAND_OUTPUT_FILE; done: BOOLEAN; index: INTEGER
		do
			expat_checksum := 0
			create output_file.make_with_output (Xml_crc_32, << type, file_path >>)
			expat_return_code := output_file.return_code
			if expat_return_code > 0 then
				expat_error := output_file.error_lines.first

			elseif output_file.has_output then
				from until done loop
					output_file.read_line
					if output_file.end_of_file then
						done := True
					elseif attached output_file.last_string as line and then line.starts_with (once "Checksum") then
						index := line.index_of (':', 1)
						expat_checksum := line.substring (index + 2, line.count).to_natural
						done := True
					end
				end
			end
			output_file.cleanup
		end

	log_checksums (insertions: ARRAY [STRING])
		do
			if package_name.is_empty then
				log.put_string ("VALUES DIFFER: " + file_path.out)
			else
				log.put_string (substitute (Values_differ_template, << package_name, file_path.out >>))
			end
			log.put_new_line
			log.put_string (substitute (Checksum_comparison, insertions))
			log.put_new_line; log.put_new_line
		end

feature {NONE} -- Internal attributes

	expat_checksum: NATURAL

	expat_error: STRING

	expat_return_code: INTEGER

	file_path: PATH

	log: PLAIN_TEXT_FILE

	package_name: STRING

	xpact_error: STRING

feature {NONE} -- Constants		

	Checksum_comparison: STRING = "Checksum for %S: Xpact=%S eXpat=%S"

	Error_template: STRING = "ERROR (%S): %S"

	Values_differ_template: STRING = "VALUES DIFFER (%S): %S"

	Xml_crc_32: STRING = "xml_crc_32 -type %S -duration 0 %S"

end
