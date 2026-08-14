note
	description: "Xpact event handling interface"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-12 07:00:00 GMT (Wednesday 12th August 2026)"
	revision: "1"

deferred class
	XT_PARSE_EVENTS

feature {NONE} -- Event handlers

	on_clear_reenter
			-- Clear the reenter flag after each loop iteration.
		do
		ensure
			cleared: not processor_wants_reenter
		end

	on_finish (a_status: INTEGER)
		do
		end

	on_start_parsing: BOOLEAN
			-- Called once when a root parser leaves State_initialized.
			-- Initialise hash salt and any implicit namespace context here.
			-- Return True on success; False causes the parse to abort with
			-- Error_no_memory (matching startParsing() in xmlparse.c).
		do
			Result := True
		end

	on_set_error_processor
		-- Switch the active processor to the error sink so that any
		-- further parse calls immediately fail.
		-- Corresponds to `m_processor = errorProcessor' in xmlparse.c.
		do
		end

	on_update_position (start_index, end_index: INTEGER)
			-- Update line/column counters by scanning
			-- `buffer [start_index .. end_index)'.
			-- Corresponds to XmlUpdatePosition() calls in xmlparse.c.
		require
			valid_range: start_index >= 0 and then start_index <= end_index
			to_in_buf: end_index <= buffer_end
		do
		end

feature {NONE} -- Deferred event handlers

	on_cdata_section_close
		deferred
		end

	on_comment (buf: like buffer; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		deferred
		end

	on_content (buf: like buffer; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		deferred
		end

	on_tag_end (name: STRING_8)
		deferred
		end

	on_tag_start (buf: like buffer; context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS; token: INTEGER)
		require
			valid_token: element_tokens.has (token)
			valid_attribute_indices_count: attributes.is_valid_count
		deferred
		end

	on_processing_instruction (buf: like buffer; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		deferred
		end

	on_xml_declaration (buf: like buffer; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		require
			valid_attribute_indices_count: attributes.is_valid_count
		deferred
		end

feature {NONE} -- Implementation

	processor_wants_reenter: BOOLEAN
		-- True when the processor has set its reenter flag, requesting
		-- another pass through `process_content' to avoid stack overflow.
		-- Corresponds to `m_reenter' in xmlparse.c.
		do
			Result := False
		end

feature {NONE} -- Deferred

	buffer_end: INTEGER
		deferred
		end

	buffer: SPECIAL [CHARACTER_8]
		deferred
		end

	element_tokens: ARRAY [INTEGER]
		deferred
		end

end
