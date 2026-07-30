/* Benchmark: expat parse of UTF-8 vs UTF-16LE input (same logical content),
   plus isolated UTF-16LE -> UTF-8 transcode loops:
     A) transliteration of EL_UTF_16_C_STRING.copy_as_utf_8 structure
     B) expat little2_toUtf8 style (byte-wise hi/lo, switch)
     C) 64-bit ASCII fast path
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#include "expat.h"

static double now (void) {
	struct timespec ts; clock_gettime (CLOCK_MONOTONIC, &ts);
	return ts.tv_sec + ts.tv_nsec * 1e-9;
}

/* ---- handlers that touch all content (approximate CRC-everything benchmark) ---- */
static unsigned long sink;
static void start_el (void *ud, const XML_Char *name, const XML_Char **atts) {
	const char *p; int i;
	for (p = name; *p; p++) sink += (unsigned char)*p;
	for (i = 0; atts [i]; i++)
		for (p = atts [i]; *p; p++) sink += (unsigned char)*p;
}
static void end_el (void *ud, const XML_Char *name) { sink += (unsigned char)name [0]; }
static void char_data (void *ud, const XML_Char *s, int len) {
	int i; for (i = 0; i < len; i++) sink += (unsigned char)s [i];
}

static double bench_expat (const char *buf, size_t len, int passes) {
	double t0 = now ();
	for (int p = 0; p < passes; p++) {
		XML_Parser parser = XML_ParserCreate (NULL);
		XML_SetElementHandler (parser, start_el, end_el);
		XML_SetCharacterDataHandler (parser, char_data);
		/* feed in 4096/8192-byte chunks like XT_XML_FILE */
		size_t chunk = 8192, off = 0;
		while (off < len) {
			size_t n = len - off < chunk ? len - off : chunk;
			if (XML_Parse (parser, buf + off, (int)n, off + n == len) == XML_STATUS_ERROR) {
				fprintf (stderr, "parse error: %s\n", XML_ErrorString (XML_GetErrorCode (parser)));
				exit (1);
			}
			off += n;
		}
		XML_ParserFree (parser);
	}
	return now () - t0;
}

/* ---- A: transliteration of the Eiffel loop (per-unit, function-call read) ---- */
__attribute__((noinline)) static uint16_t read_natural_16 (const void *area, int i) {
	return ((const uint16_t *)area) [i];
}
static int copy_as_utf_8_eiffel (const void *area, int byte_count, char *dest, int dest_index, int n,
                                 int *utf_8_copied_count, int *last_index) {
	int dest_full = 0, partial_pair = 0;
	int i, i_final, j, remaining_count, code_unit, code_unit_count;
	code_unit_count = byte_count / 2;
	i_final = code_unit_count - 1;
	remaining_count = n;
	for (i = 0, j = dest_index; !(i > i_final || dest_full || partial_pair); ) {
		code_unit = read_natural_16 (area, i);
		if (code_unit < 0x80) {
			if (remaining_count == 0) dest_full = 1;
			else { dest [j] = (char)code_unit; j++; remaining_count--; i++; }
		} else if (code_unit < 0x800) {
			if (remaining_count <= 1) dest_full = 1;
			else {
				dest [j] = (char)(0xC0 | (code_unit >> 6));
				dest [j + 1] = (char)(0x80 | (code_unit & 0x3F));
				j += 2; remaining_count -= 2; i++;
			}
		} else if (code_unit >= 0xD800 && code_unit <= 0xDBFF) {
			partial_pair = 1; /* not exercised: test data is BMP only */
		} else {
			if (remaining_count <= 2) dest_full = 1;
			else {
				dest [j] = (char)(0xE0 | (code_unit >> 12));
				dest [j + 1] = (char)(0x80 | ((code_unit >> 6) & 0x3F));
				dest [j + 2] = (char)(0x80 | (code_unit & 0x3F));
				j += 3; remaining_count -= 3; i++;
			}
		}
	}
	*utf_8_copied_count = n - remaining_count;
	*last_index = i * 2;
	return dest_full;
}

/* Same loop but with the read inlined (what EiffelStudio *should* produce) */
static int copy_as_utf_8_eiffel_inlined (const void *area, int byte_count, char *dest, int dest_index, int n,
                                         int *utf_8_copied_count, int *last_index) {
	const uint16_t *u = (const uint16_t *)area;
	int dest_full = 0, partial_pair = 0;
	int i, i_final, j, remaining_count, code_unit, code_unit_count;
	code_unit_count = byte_count / 2;
	i_final = code_unit_count - 1;
	remaining_count = n;
	for (i = 0, j = dest_index; !(i > i_final || dest_full || partial_pair); ) {
		code_unit = u [i];
		if (code_unit < 0x80) {
			if (remaining_count == 0) dest_full = 1;
			else { dest [j] = (char)code_unit; j++; remaining_count--; i++; }
		} else if (code_unit < 0x800) {
			if (remaining_count <= 1) dest_full = 1;
			else {
				dest [j] = (char)(0xC0 | (code_unit >> 6));
				dest [j + 1] = (char)(0x80 | (code_unit & 0x3F));
				j += 2; remaining_count -= 2; i++;
			}
		} else if (code_unit >= 0xD800 && code_unit <= 0xDBFF) {
			partial_pair = 1;
		} else {
			if (remaining_count <= 2) dest_full = 1;
			else {
				dest [j] = (char)(0xE0 | (code_unit >> 12));
				dest [j + 1] = (char)(0x80 | ((code_unit >> 6) & 0x3F));
				dest [j + 2] = (char)(0x80 | (code_unit & 0x3F));
				j += 3; remaining_count -= 3; i++;
			}
		}
	}
	*utf_8_copied_count = n - remaining_count;
	*last_index = i * 2;
	return dest_full;
}

/* ---- C: 64-bit ASCII fast path ---- */
static int copy_as_utf_8_fast (const void *area, int byte_count, char *dest, int dest_index, int n,
                               int *utf_8_copied_count, int *last_index) {
	const uint16_t *u = (const uint16_t *)area;
	int count = byte_count / 2;
	int i = 0, j = dest_index;
	int j_lim = dest_index + n;
	while (i + 4 <= count && j + 4 <= j_lim) {
		uint64_t four; memcpy (&four, u + i, 8);
		if (four & 0xFF80FF80FF80FF80ULL) break;
		uint32_t packed = (uint32_t)((four & 0x7F) | ((four >> 8) & 0x7F00)
			| ((four >> 16) & 0x7F0000) | ((four >> 24) & 0x7F000000));
		memcpy (dest + j, &packed, 4);
		i += 4; j += 4;
	}
	while (i < count) {
		unsigned code_unit = u [i];
		if (code_unit < 0x80) {
			if (j >= j_lim) break;
			dest [j++] = (char)code_unit; i++;
			/* re-enter the wide loop after a stray non-ASCII run ends */
			while (i + 4 <= count && j + 4 <= j_lim) {
				uint64_t four; memcpy (&four, u + i, 8);
				if (four & 0xFF80FF80FF80FF80ULL) break;
				uint32_t packed = (uint32_t)((four & 0x7F) | ((four >> 8) & 0x7F00)
					| ((four >> 16) & 0x7F0000) | ((four >> 24) & 0x7F000000));
				memcpy (dest + j, &packed, 4);
				i += 4; j += 4;
			}
		} else if (code_unit < 0x800) {
			if (j + 2 > j_lim) break;
			dest [j] = (char)(0xC0 | (code_unit >> 6));
			dest [j + 1] = (char)(0x80 | (code_unit & 0x3F));
			j += 2; i++;
		} else if (code_unit >= 0xD800 && code_unit <= 0xDBFF) {
			break; /* BMP-only test data */
		} else {
			if (j + 3 > j_lim) break;
			dest [j] = (char)(0xE0 | (code_unit >> 12));
			dest [j + 1] = (char)(0x80 | ((code_unit >> 6) & 0x3F));
			dest [j + 2] = (char)(0x80 | (code_unit & 0x3F));
			j += 3; i++;
		}
	}
	*utf_8_copied_count = j - dest_index;
	*last_index = i * 2;
	return 0;
}

int main (int argc, char **argv) {
	/* load files */
	FILE *f8 = fopen ("doc_utf8.xml", "rb"), *f16 = fopen ("doc_utf16.xml", "rb");
	if (!f8 || !f16) { fprintf (stderr, "missing test files\n"); return 1; }
	fseek (f8, 0, SEEK_END); long len8 = ftell (f8); fseek (f8, 0, SEEK_SET);
	fseek (f16, 0, SEEK_END); long len16 = ftell (f16); fseek (f16, 0, SEEK_SET);
	char *buf8 = malloc (len8), *buf16 = malloc (len16);
	fread (buf8, 1, len8, f8); fread (buf16, 1, len16, f16);
	fclose (f8); fclose (f16);

	int passes = atoi (argv [1]);

	/* warm */
	bench_expat (buf8, len8, 50); bench_expat (buf16, len16, 50);

	double t8 = bench_expat (buf8, len8, passes);
	double t16 = bench_expat (buf16, len16, passes);
	printf ("expat UTF-8  parse : %8.1f MB/s  (%.3fs, %ld bytes)\n", len8 * passes / t8 / 1e6, t8, len8);
	printf ("expat UTF-16 parse : %8.1f MB/s  (%.3fs, %ld bytes)  penalty vs UTF-8 (per logical char): x%.2f\n",
		len16 * passes / t16 / 1e6, t16, len16, (t16 / passes) / (t8 / passes));

	/* isolated transcode: skip BOM, convert whole doc chunk-wise (8192-byte chunks, 4096-byte dest budget) */
	char *dest = malloc (len16);
	int copied, last;
	int tpasses = passes * 4;
	double ta, tb, tc;
	volatile int guard = 0;

	double t0 = now ();
	for (int p = 0; p < tpasses; p++)
		for (long off = 2; off < len16; off += 8192) {
			long nb = len16 - off < 8192 ? len16 - off : 8192;
			guard += copy_as_utf_8_eiffel (buf16 + off, (int)nb, dest, 0, (int)nb / 2, &copied, &last);
		}
	ta = now () - t0;

	t0 = now ();
	for (int p = 0; p < tpasses; p++)
		for (long off = 2; off < len16; off += 8192) {
			long nb = len16 - off < 8192 ? len16 - off : 8192;
			guard += copy_as_utf_8_eiffel_inlined (buf16 + off, (int)nb, dest, 0, (int)nb / 2, &copied, &last);
		}
	tb = now () - t0;

	t0 = now ();
	for (int p = 0; p < tpasses; p++)
		for (long off = 2; off < len16; off += 8192) {
			long nb = len16 - off < 8192 ? len16 - off : 8192;
			guard += copy_as_utf_8_fast (buf16 + off, (int)nb, dest, 0, (int)nb / 2, &copied, &last);
		}
	tc = now () - t0;

	double mb = (double)(len16 - 2) * tpasses / 1e6;
	printf ("\ntranscode UTF-16LE -> UTF-8 (mostly ASCII), input MB/s:\n");
	printf ("  A) Eiffel-structure loop, call per unit : %8.1f MB/s\n", mb / ta);
	printf ("  B) same loop, read inlined              : %8.1f MB/s\n", mb / tb);
	printf ("  C) 64-bit ASCII fast path               : %8.1f MB/s\n", mb / tc);
	printf ("\ntranscode cost as fraction of one expat UTF-16 parse of same doc:\n");
	printf ("  A: %5.1f%%   B: %5.1f%%   C: %5.1f%%\n",
		100.0 * (ta / tpasses) / (t16 / passes),
		100.0 * (tb / tpasses) / (t16 / passes),
		100.0 * (tc / tpasses) / (t16 / passes));
	printf ("(sink=%lu guard=%d)\n", sink, guard);
	return 0;
}
