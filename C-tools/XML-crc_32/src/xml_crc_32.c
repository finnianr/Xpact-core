/*
 * xml_crc_32 - compute a CRC-32/ISO-HDLC checksum over a chosen data
 * dimension (text, cdata, comment, tag, attribute) of an XML document,
 * parsed with libexpat.
 */

#define _POSIX_C_SOURCE 200809L

#include <expat.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <libgen.h>

typedef enum {
	TYPE_TEXT,
	TYPE_CDATA,
	TYPE_COMMENT,
	TYPE_TAG,
	TYPE_ATTRIBUTE,
	TYPE_ATTRIB_NAME,
	TYPE_PI_NAME,
	TYPE_PI_DATA,
	TYPE_XML_DECL,
	TYPE_DOCTYPE,
	TYPE_ATTLIST,
	TYPE_ENTITY
} data_type_t;

static const char *data_type_name[] = {
	"text", "cdata", "comment", "tag", "attribute", "attrib-name",
	"pi-name", "pi-data", "xml-decl", "doctype", "attlist", "entity"
};

typedef struct {
	data_type_t type;
	int         trace;
	int         verbose_output; /* only true on the first pass */
	uint32_t    crc;
	int         event_count;
	int         in_cdata;
} crc_ctx_t;

static uint32_t crc32_table[256];

static void crc32_table_init(void) {
	for (uint32_t i = 0; i < 256; i++) {
		uint32_t c = i;
		for (int k = 0; k < 8; k++) {
			c = (c & 1) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
		}
		crc32_table[i] = c;
	}
}

static void println_escaped(const char *s, int len);

static void crc32_bytes(crc_ctx_t *ctx, const unsigned char *buf, size_t len) {
	uint32_t crc = ctx->crc;
	for (size_t i = 0; i < len; i++) {
		crc = crc32_table[(crc ^ buf[i]) & 0xFFu] ^ (crc >> 8);
	}
	ctx->crc = crc;
	ctx->event_count++;
}

static void crc32_update(crc_ctx_t *ctx, const unsigned char *buf, size_t len) {
	crc32_bytes(ctx, buf, len);
	if (ctx->trace && ctx->verbose_output) {
		printf("#%07d (%u): \"", ctx->event_count, ctx->crc ^ 0xFFFFFFFFu);
		println_escaped ((const char *) buf, len);
	}
}

/* Same CRC update as crc32_update, but for a signed 32-bit value fed in as
 * 4 raw big-endian bytes; traced as a decimal integer rather than an
 * escaped byte string. Used for the XML declaration's standalone field. */
static void crc32_update_int32(crc_ctx_t *ctx, int32_t value) {
	crc32_bytes(ctx, (const unsigned char *)&value, sizeof(int32_t));
	if (ctx->trace && ctx->verbose_output) {
		printf("#%07d (%u): %d\n", ctx->event_count, ctx->crc ^ 0xFFFFFFFFu, value);
	}
}

/* Same CRC update as crc32_update, but for a boolean value fed in as a
 * single byte (0 or 1); traced as "True"/"False" rather than an escaped
 * byte string. Used for the doctype's has_internal_subset field. */
static void crc32_update_bool(crc_ctx_t *ctx, int value) {
	unsigned char byte = value ? 1u : 0u;
	crc32_bytes(ctx, &byte, sizeof(byte));
	if (ctx->trace && ctx->verbose_output) {
		printf("#%07d (%u): %s\n", ctx->event_count, ctx->crc ^ 0xFFFFFFFFu,
		       value ? "True" : "False");
	}
}

/* Stub handler for external parameter entities (e.g. %selectors; in XSL files).
 * Without this, expat sets dtd->keepProcessing=false when it hits an external
 * parameter entity ref and has no handler, which silently discards all entity
 * declarations that follow it in the internal subset.
 * Calling XML_Parse on the sub-parser (even with empty content) sets
 * dtd->paramEntityRead=true, which keeps keepProcessing=true. */
static int XMLCALL on_external_entity(XML_Parser parser,
                                      const XML_Char *context,
                                      const XML_Char *base,
                                      const XML_Char *systemId,
                                      const XML_Char *publicId)
{
	(void)base; (void)systemId; (void)publicId;
	XML_Parser sub = XML_ExternalEntityParserCreate(parser, context, NULL);
	if (sub) {
		XML_Parse(sub, "", 0, 1);
		XML_ParserFree(sub);
	}
	return 1;
}

static void XMLCALL on_start_cdata(void *userData) {
	crc_ctx_t *ctx = (crc_ctx_t *) userData;
	ctx->in_cdata = 1;
}

static void XMLCALL on_end_cdata(void *userData) {
	crc_ctx_t *ctx = (crc_ctx_t *) userData;
	ctx->in_cdata = 0;
}

static void XMLCALL on_character_data(void *userData, const XML_Char *s, int len) {
	crc_ctx_t *ctx = (crc_ctx_t *) userData;
	if (ctx->type == TYPE_TEXT && !ctx->in_cdata) {
		crc32_update(ctx, (const unsigned char *) s, (size_t) len);
	} else if (ctx->type == TYPE_CDATA && ctx->in_cdata) {
		crc32_update(ctx, (const unsigned char *) s, (size_t) len);
	}
}

static void XMLCALL on_processing_instruction(void *userData,
                                               const XML_Char *target,
                                               const XML_Char *data) {
	crc_ctx_t *ctx = (crc_ctx_t *) userData;
	if (ctx->type == TYPE_PI_NAME) {
		crc32_update(ctx, (const unsigned char *) target, strlen(target));
	} else if (ctx->type == TYPE_PI_DATA) {
		if (data && *data)
			crc32_update(ctx, (const unsigned char *) data, strlen(data));
	}
}

static void XMLCALL on_comment(void *userData, const XML_Char *data) {
	crc_ctx_t *ctx = (crc_ctx_t *) userData;
	if (ctx->type == TYPE_COMMENT) {
		crc32_update(ctx, (const unsigned char *) data, strlen(data));
	}
}

static void XMLCALL on_start_element(void *userData, const XML_Char *name,
									  const XML_Char **atts) {
	crc_ctx_t *ctx = (crc_ctx_t *) userData;
	if (ctx->type == TYPE_TAG) {
		crc32_update(ctx, (const unsigned char *) name, strlen(name));
	} else if (ctx->type == TYPE_ATTRIBUTE) {
		for (int i = 0; atts[i]; i += 2) {
			crc32_update(ctx, (const unsigned char *) atts[i + 1], strlen(atts[i + 1]));
		}
	} else if (ctx->type == TYPE_ATTRIB_NAME) {
		for (int i = 0; atts[i]; i += 2) {
			crc32_update(ctx, (const unsigned char *) atts[i], strlen(atts[i]));
		}
	}
}

/* Combines the XML declaration's version, encoding and standalone fields
 * (as supplied to XML_XmlDeclHandler) into the running checksum. encoding
 * is NULL when absent from the declaration; standalone is -1 when absent,
 * 0 for standalone="no", 1 for standalone="yes". */
static void XMLCALL on_xml_decl(void *userData, const XML_Char *version,
                                 const XML_Char *encoding, int standalone) {
	crc_ctx_t *ctx = (crc_ctx_t *) userData;
	if (ctx->type != TYPE_XML_DECL) return;
	if (version)
		crc32_update(ctx, (const unsigned char *) version, strlen(version));
	if (encoding)
		crc32_update(ctx, (const unsigned char *) encoding, strlen(encoding));
	crc32_update_int32 (ctx, standalone); // can have -1 as value, so not a boolean
}

/* Combines the DOCTYPE declaration's name, external ID keyword ("PUBLIC" or
 * "SYSTEM", omitted when neither id is present), public id, system id and
 * has_internal_subset flag (as supplied to XML_StartDoctypeDeclHandler)
 * into the running checksum. */
static void XMLCALL on_start_doctype_decl(void *userData, const XML_Char *doctypeName,
                                           const XML_Char *sysid, const XML_Char *pubid,
                                           int has_internal_subset) {
	crc_ctx_t *ctx = (crc_ctx_t *) userData;
	if (ctx->type != TYPE_DOCTYPE) return;
	crc32_update(ctx, (const unsigned char *) doctypeName, strlen(doctypeName));
	if (pubid) {
		crc32_update(ctx, (const unsigned char *) "PUBLIC", strlen("PUBLIC"));
		crc32_update(ctx, (const unsigned char *) pubid, strlen(pubid));
		if (sysid)
			crc32_update(ctx, (const unsigned char *) sysid, strlen(sysid));
	} else if (sysid) {
		crc32_update(ctx, (const unsigned char *) "SYSTEM", strlen("SYSTEM"));
		crc32_update(ctx, (const unsigned char *) sysid, strlen(sysid));
	}
	crc32_update_bool(ctx, has_internal_subset);
}

/* Combines the ATTLIST declaration's fields, left to right as supplied to
 * XML_AttlistDeclHandler, into the running checksum: elname, attname,
 * att_type, dflt (skipped when NULL), isrequired. */
static void XMLCALL on_attlist_decl(void *userData, const XML_Char *elname,
                                     const XML_Char *attname, const XML_Char *att_type,
                                     const XML_Char *dflt, int isrequired) {
	crc_ctx_t *ctx = (crc_ctx_t *) userData;
	if (ctx->type != TYPE_ATTLIST) return;
	crc32_update(ctx, (const unsigned char *) elname, strlen(elname));
	crc32_update(ctx, (const unsigned char *) attname, strlen(attname));
	crc32_update(ctx, (const unsigned char *) att_type, strlen(att_type));
	if (dflt)
		crc32_update(ctx, (const unsigned char *) dflt, strlen(dflt));
	crc32_update_bool(ctx, isrequired);
}

/* Combines the ENTITY declaration's fields, left to right as supplied to
 * XML_EntityDeclHandler, into the running checksum: entityName,
 * is_parameter_entity, value, base, systemId, publicId, notationName.
 * value is not NUL-terminated, so value_length is used directly rather
 * than strlen; value/base/systemId/publicId/notationName are skipped
 * when NULL. */
static void XMLCALL on_entity_decl(void *userData, const XML_Char *entityName,
                                    int is_parameter_entity, const XML_Char *value,
                                    int value_length, const XML_Char *base,
                                    const XML_Char *systemId, const XML_Char *publicId,
                                    const XML_Char *notationName) {
	crc_ctx_t *ctx = (crc_ctx_t *) userData;
	if (ctx->type != TYPE_ENTITY) return;
	crc32_update(ctx, (const unsigned char *) entityName, strlen(entityName));
	crc32_update_bool(ctx, is_parameter_entity);
	if (value){
		crc32_update(ctx, (const unsigned char *) value, (size_t) value_length);
		crc32_update_int32(ctx, value_length);
	}
	if (base)
		crc32_update(ctx, (const unsigned char *) base, strlen(base));
	if (systemId)
		crc32_update(ctx, (const unsigned char *) systemId, strlen(systemId));
	if (publicId)
		crc32_update(ctx, (const unsigned char *) publicId, strlen(publicId));
	if (notationName)
		crc32_update(ctx, (const unsigned char *) notationName, strlen(notationName));
}

#define CHUNK_SIZE 4096

/* Parses the file incrementally in 4096-byte chunks, feeding events into ctx.
 * Returns the finalized CRC-32 value for this pass. */
static uint32_t run_pass(const char *file_path, crc_ctx_t *ctx) {
	ctx->crc = 0xFFFFFFFFu;
	ctx->event_count = 0;
	ctx->in_cdata = 0;

	FILE *fp = fopen(file_path, "rb");
	if (!fp) {
		fprintf(stderr, "Error: could not open file '%s'\n", file_path);
		exit(1);
	}

	XML_Parser parser = XML_ParserCreate(NULL);
	if (!parser) {
		fprintf(stderr, "Error: could not create expat parser\n");
		fclose(fp);
		exit(1);
	}

	XML_SetUserData(parser, ctx);
	XML_SetParamEntityParsing(parser, XML_PARAM_ENTITY_PARSING_ALWAYS);
	XML_SetExternalEntityRefHandler(parser, on_external_entity);
	XML_SetElementHandler(parser, on_start_element, NULL);
	XML_SetCharacterDataHandler(parser, on_character_data);
	XML_SetCommentHandler(parser, on_comment);
	XML_SetCdataSectionHandler(parser, on_start_cdata, on_end_cdata);
	XML_SetProcessingInstructionHandler(parser, on_processing_instruction);
	XML_SetXmlDeclHandler(parser, on_xml_decl);
	XML_SetStartDoctypeDeclHandler(parser, on_start_doctype_decl);
	XML_SetAttlistDeclHandler(parser, on_attlist_decl);
	XML_SetEntityDeclHandler(parser, on_entity_decl);

	char buf[CHUNK_SIZE];
	int done = 0;
	while (!done) {
		size_t len = fread(buf, 1, CHUNK_SIZE, fp);
		done = len < CHUNK_SIZE;
		if (XML_Parse(parser, buf, (int) len, done) == XML_STATUS_ERROR) {
			fprintf(stderr, "Parse error: %s at line %lu\n",
					XML_ErrorString(XML_GetErrorCode(parser)),
					XML_GetCurrentLineNumber(parser));
			XML_ParserFree(parser);
			fclose(fp);
			exit(1);
		}
	}

	fclose(fp);
	uint32_t result = ctx->crc ^ 0xFFFFFFFFu;
	XML_ParserFree(parser);
	return result;
}

static long now_ms(void) {
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return ts.tv_sec * 1000L + ts.tv_nsec / 1000000L;
}

static void usage(const char *prog) {
	fprintf(stderr,
			"Usage: %s -type <text|cdata|comment|tag|attribute|attrib-name|"
			"pi-name|pi-data|xml-decl|doctype|attlist|entity> "
			"[-duration <time-window-ms>] [-trace] <xml-file-path>\n",
			prog);
}

static void println_escaped (const char *s, int len) {
	char code;
	for (int i = 0; i < len; i++) {
		switch (s[i]) {
			case '\n':
				code = 'N';
				break;
			case '\t':
				code = 'T';
				break;
			case '\r':
				code = 'R';
				break;
			default:
				code = '\0';
				putchar(s[i]);
				break;
		}
		if (code){
			putchar('%');
			putchar(code);
		}
	}
	putchar('"');
	putchar('\n');
}

#include <stdio.h>

// claude --resume 344f37b9-23a1-4eac-94de-245352a8d82d

int main(int argc, char **argv) {
	const char *type_arg = NULL;
	const char *file_path = NULL;
	long duration_ms = 0;
	int trace = 0;

	for (int i = 1; i < argc; i++) {
		if (strcmp(argv[i], "-type") == 0) {
			if (++i >= argc) { usage(argv[0]); return 1; }
			type_arg = argv[i];
		} else if (strcmp(argv[i], "-duration") == 0) {
			if (++i >= argc) { usage(argv[0]); return 1; }
			duration_ms = strtol(argv[i], NULL, 10);
		} else if (strcmp(argv[i], "-trace") == 0) {
			trace = 1;
		} else {
			file_path = argv[i];
		}
	}

	if (!type_arg || !file_path) {
		usage(argv[0]);
		return 1;
	}

	data_type_t type;
	if (strcmp(type_arg, "text") == 0) type = TYPE_TEXT;
	else if (strcmp(type_arg, "cdata") == 0) type = TYPE_CDATA;
	else if (strcmp(type_arg, "comment") == 0) type = TYPE_COMMENT;
	else if (strcmp(type_arg, "tag") == 0) type = TYPE_TAG;
	else if (strcmp(type_arg, "attribute") == 0) type = TYPE_ATTRIBUTE;
	else if (strcmp(type_arg, "attrib-name") == 0) type = TYPE_ATTRIB_NAME;
	else if (strcmp(type_arg, "pi-name") == 0) type = TYPE_PI_NAME;
	else if (strcmp(type_arg, "pi-data") == 0) type = TYPE_PI_DATA;
	else if (strcmp(type_arg, "xml-decl") == 0) type = TYPE_XML_DECL;
	else if (strcmp(type_arg, "doctype") == 0) type = TYPE_DOCTYPE;
	else if (strcmp(type_arg, "attlist") == 0) type = TYPE_ATTLIST;
	else if (strcmp(type_arg, "entity") == 0) type = TYPE_ENTITY;
	else {
		fprintf(stderr, "Error: invalid -type '%s'\n", type_arg);
		usage(argv[0]);
		return 1;
	}

	crc32_table_init();

	char *path_copy = strdup(file_path);
	printf("Program: eXpat XML CRC-32 parser (C lang)\n");
	printf("Parsing: %s\n", basename(path_copy));
	free(path_copy);

	crc_ctx_t ctx;
	ctx.type = type;
	ctx.trace = trace;

	ctx.verbose_output = 1;
	uint32_t checksum = run_pass(file_path, &ctx);
	printf("Checksum for %s: %u\n", data_type_name[type], checksum);

	if (duration_ms > 0) {
		ctx.verbose_output = 0;
		long start = now_ms();
		long passes = 1; /* the pass already completed above */
		while (now_ms() - start < duration_ms) {
			run_pass(file_path, &ctx);
			passes++;
		}
		printf("Number of passes in %ld ms: %ld\n", duration_ms, passes);
	}

	return 0;
}
