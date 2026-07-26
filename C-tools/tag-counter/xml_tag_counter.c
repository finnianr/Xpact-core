#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <expat.h>

#define BUF_SIZE 4096
#define HASH_BUCKETS 257

typedef struct TagNode {
	char *name;
	long count;
	struct TagNode *next;
} TagNode;

static TagNode *buckets[HASH_BUCKETS];
static int n_distinct = 0;

static unsigned long
hash_str(const char *s) {
	unsigned long h = 5381;
	int c;
	while ((c = (unsigned char)*s++))
		h = ((h << 5) + h) + c;
	return h;
}

static void
tag_increment(const char *name) {
	unsigned long idx = hash_str(name) % HASH_BUCKETS;
	TagNode *node = buckets[idx];
	while (node) {
		if (strcmp(node->name, name) == 0) {
			node->count++;
			return;
		}
		node = node->next;
	}
	node = malloc(sizeof(TagNode));
	node->name = strdup(name);
	node->count = 1;
	node->next = buckets[idx];
	buckets[idx] = node;
	n_distinct++;
}

static void XMLCALL
start_element(void *userData, const XML_Char *name, const XML_Char **atts) {
	(void)userData;
	(void)atts;
	tag_increment(name);
}

typedef struct {
	const char *name;
	long count;
} FlatEntry;

static int
compare_entries(const void *a, const void *b) {
	const FlatEntry *fa = (const FlatEntry *)a;
	const FlatEntry *fb = (const FlatEntry *)b;
	if (fb->count != fa->count)
		return (fb->count > fa->count) - (fb->count < fa->count);
	return strcmp(fa->name, fb->name);
}

static void
free_table(void) {
	for (int i = 0; i < HASH_BUCKETS; i++) {
		TagNode *node = buckets[i];
		while (node) {
			TagNode *next = node->next;
			free(node->name);
			free(node);
			node = next;
		}
		buckets[i] = NULL;
	}
	n_distinct = 0;
}

static int
parse_file(const char *path) {
	FILE *f = fopen(path, "rb");
	if (!f) { perror("fopen"); return 0; }

	XML_Parser parser = XML_ParserCreate(NULL);
	XML_SetElementHandler(parser, start_element, NULL);

	char buf[BUF_SIZE];
	int ok = 1;
	while (ok) {
		size_t len = fread(buf, 1, BUF_SIZE, f);
		int done = len < BUF_SIZE;
		if (XML_Parse(parser, buf, (int)len, done) == XML_STATUS_ERROR) {
			fprintf(stderr, "Parse error at line %lu: %s\n",
					XML_GetCurrentLineNumber(parser),
					XML_ErrorString(XML_GetErrorCode(parser)));
			ok = 0;
		}
		if (done) break;
	}

	fclose(f);
	XML_ParserFree(parser);
	return ok;
}

static double
elapsed_ms(const struct timespec *start) {
	struct timespec now;
	clock_gettime(CLOCK_MONOTONIC, &now);
	return (now.tv_sec - start->tv_sec) * 1000.0 +
	       (now.tv_nsec - start->tv_nsec) / 1.0e6;
}

int main(int argc, char *argv[]) {
	int duration_ms = 500;
	const char *path = NULL;

	for (int i = 1; i < argc; i++) {
		if (strcmp(argv[i], "-duration") == 0 && i + 1 < argc) {
			duration_ms = atoi(argv[++i]);
		} else {
			path = argv[i];
		}
	}

	if (!path) {
		fprintf(stderr, "Usage: %s [-duration <ms>] <file.xml>\n", argv[0]);
		return 1;
	}

	printf("Program: eXpat XML parser (pure C)\n");
	printf("Parsing: %s\n", path);
	printf("Tags sorted in order of occurrence count (Highest first)\n\n");

	struct timespec t_start;
	clock_gettime(CLOCK_MONOTONIC, &t_start);

	int passes = 0;

	while (1) {
		if (!parse_file(path)) return 1;
		passes++;

		if (passes == 1) {
			FlatEntry *flat = malloc(sizeof(FlatEntry) * n_distinct);
			int idx = 0;
			for (int i = 0; i < HASH_BUCKETS; i++)
				for (TagNode *node = buckets[i]; node; node = node->next) {
					flat[idx].name = node->name;
					flat[idx].count = node->count;
					idx++;
				}
			qsort(flat, n_distinct, sizeof(FlatEntry), compare_entries);
			for (int i = 0; i < n_distinct; i++)
				printf("TAG: <%s> occurrences %ld\n", flat[i].name, flat[i].count);
			printf("\n");
			free(flat);
		}

		if (elapsed_ms(&t_start) >= duration_ms) break;
		free_table();
	}

	free_table();
	printf("Number of passes in %d ms: %d\n", duration_ms, passes);
	return 0;
}
