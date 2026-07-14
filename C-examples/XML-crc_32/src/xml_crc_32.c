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
	TYPE_ATTRIBUTE
} data_type_t;

static const char *data_type_name[] = {
	"text", "cdata", "comment", "tag", "attribute"
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

static void crc32_update(crc_ctx_t *ctx, const unsigned char *buf, size_t len) {
	uint32_t crc = ctx->crc;
	for (size_t i = 0; i < len; i++) {
		crc = crc32_table[(crc ^ buf[i]) & 0xFFu] ^ (crc >> 8);
	}
	ctx->crc = crc;

	ctx->event_count++;
	if (ctx->trace && ctx->verbose_output) {
		printf("%d. %u\n", ctx->event_count, ctx->crc ^ 0xFFFFFFFFu);
	}
}

static void println_escaped(const char *s, int len);

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
		if (ctx->trace && ctx->verbose_output) println_escaped((const char *) s, len);
		crc32_update(ctx, (const unsigned char *) s, (size_t) len);
	} else if (ctx->type == TYPE_CDATA && ctx->in_cdata) {
		if (ctx->trace && ctx->verbose_output) println_escaped((const char *) s, len);
		crc32_update(ctx, (const unsigned char *) s, (size_t) len);
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
			if (ctx->trace && ctx->verbose_output) printf("%s\n", atts[i + 1]);
			crc32_update(ctx, (const unsigned char *) atts[i + 1], strlen(atts[i + 1]));
		}
	}
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
	XML_SetElementHandler(parser, on_start_element, NULL);
	XML_SetCharacterDataHandler(parser, on_character_data);
	XML_SetCommentHandler(parser, on_comment);
	XML_SetCdataSectionHandler(parser, on_start_cdata, on_end_cdata);

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
			"Usage: %s -type <text|cdata|comment|tag|attribute> "
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
