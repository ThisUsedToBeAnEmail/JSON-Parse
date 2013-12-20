#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <setjmp.h>
#include <ctype.h>
#include <time.h>

static void
croak (char * format, ...)
{
    exit (EXIT_FAILURE);
}

#include "unicode.h"
#include "unicode.c"
#define TESTRANDOM
#define Newx(a,b,c) a = malloc (b*sizeof (c))
#define Renew(a,b,c) a = realloc (a, b*sizeof (c))
#define Safefree(a) free (a)

#include "Json3-perl-common.c"
#include "Json3-perl.c"
#define NOPERL
#undef TESTRANDOM
#include "Json3-entry-points.c"

#define MAXBYTE 0x80
#define INITIALLENGTH 0x1000

static void
print_json_char (unsigned char c)
{
    if (isprint (c)) {
	if (c == ' ') {
	    printf (" ");
	}
	else {
	    printf ("%c", c);
	}
    }
    else {
	switch (c) {
	case '\r':
	    printf ("\\r");
	    break;
	case '\t':
	    printf ("\\t");
	    break;
	case '\f':
	    printf ("\\f");
	    break;
	case '\n':
	    printf ("\\n");
	    break;
	default:
	    printf ("0X%02X", c);
	}
    }
}

static void
print_json (parser_t * parser)
{
    int i;
    char * json;
    json = parser->input;
    printf ("JSON is now: ");
    for (i = 0; i < parser->length; i++) {
	print_json_char (json[i]);
    }
    printf ("\n");
}

/* Reset the parser to the initial state. */

static void
reset_parser (parser_t * parser)
{
    /* Reset the parser to start from the beginning. */
    parser->end = parser->input;
    parser->expected = 0;
    parser->error = json_error_invalid;
    parser->bad_byte = 0;
    parser->last_byte = parser->input + parser->length;
}

/* Alter the final byte and run again, and see if an error is
   produced. */

static void
alter_one_byte (parser_t * parser)
{
    int i;
    int valid_bytes[MAXBYTE];
    int choose[MAXBYTE];
    int n_choose;
    char * expected_bad_byte;

    n_choose = 0;

    if (! parser->bad_byte) {
	fprintf (stderr, "no bad byte in parser.\n");
	exit (1);
    }

    expected_bad_byte = parser->bad_byte;
    //    printf ("%p %p %p %p\n", expected_bad_byte, parser->input, parser->last_byte, parser->end);
    for (i = 0; i < MAXBYTE; i++) {
	valid_bytes[i] = parser->valid_bytes[i];
    }

    for (i = 0; i < MAXBYTE; i++) {
	if (! valid_bytes[i]) {
#if 0
	    printf ("I don't think that ");
	    print_json_char (i);
	    printf (" is OK\n");
#endif
	    if (setjmp (parser->biscuit)) {
		/* Failed. */
		if (parser->bad_byte != expected_bad_byte) {
		    if ((i == ']' ||
			 i == '}')) {
			/* End of numbers causes these problems,
			   cannot fix without huge efforts. */
		    }
		    else {
			fprintf (stderr, "Failed to detect error in %s with bad byte ",
				type_names[parser->bad_type]);
		    print_json_char (*expected_bad_byte);
		    printf (":\n");
		    print_json (parser);
		    fprintf (stderr,
			     "parser->bad_byte=%p should be %p with byte %d.\n",
			     parser->bad_byte, expected_bad_byte, i);
		    exit (EXIT_FAILURE);
		    }
		}
		else {
		    //		    printf ("Bad byte as expected.\n");
		}
	    }
	    else {
		/* Change the byte to the supposedly invalid value. Use
		   "expected_bad_byte" because the parser's bad_byte is
		   reset each time. */
		//printf ("Setting value to %d\n", i);
		* expected_bad_byte = i;
		//		print_json (parser);
		reset_parser (parser);
		c_validate (parser);
	    }
	}
	else {
#if 0
	    printf ("I think that ");
	    print_json_char (i);
	    printf (" is OK\n");
#endif
	    choose[n_choose] = i;
	    n_choose++;
	    if (setjmp (parser->biscuit)) {
		if (parser->bad_byte == expected_bad_byte) {
		    if ((i == ']' ||
			 i == '}')) {
			/* End of numbers causes these problems,
			   cannot fix without huge efforts. */
		    }
		    else {
		    print_json (parser);
		    fprintf (stderr,
			     "Got error %s to %p with supposedly valid value wanted %p with byte %d.\n",
			     parser->last_error, parser->bad_byte, expected_bad_byte, i);
		    exit (EXIT_FAILURE);
		    }
		}
	    }
	    else {
		/* Change the byte to the supposedly valid value. Use
		   "expected_bad_byte" because the parser's bad_byte is
		   reset each time. */
		//		printf ("Setting value to valid value %d\n", i);
		* expected_bad_byte = i;
		//		print_json (parser->input, parser->length);
		reset_parser (parser);
		c_validate (parser);
	    }
	}
    }
    
    /* Finally, stuff a random byte into the thing. */
    * expected_bad_byte = choose[random () % n_choose];
#if 0
    printf ("Chossing byte '%c' %X\n", * expected_bad_byte, * expected_bad_byte);
#endif
    /* We now have one more valid byte, and only the last byte is
       questionable. */
    parser->length++;
}

static void
random_json ()
{
    char * json;
    int json_size;
    int json_length;
    int i;
    parser_t parser_o = {0};

    json_size = INITIALLENGTH;
    json = malloc (json_size);
    if (! json) {
	fprintf (stderr, "%s:%d: out of memory.\n", __FILE__, __LINE__);
	exit (EXIT_FAILURE);
    }
    json_length = 0;
    for (i = 0; i < json_size; i++) {
	json[i] = 0;
    }
    parser_o.input = json;
    parser_o.randomtest = 1;
    for (i = 1; i < json_size; i++) {
	reset_parser (& parser_o);
	json_length = i;
	parser_o.length = json_length;
	parser_o.last_byte = parser_o.input + parser_o.length;
#if 0
	printf ("Attempting to parse length %d\n", i);
	print_json (& parser_o);
#endif
	if (setjmp (parser_o.biscuit)) {
#if 0
	    int j;
#endif
	    /*
	    if (parser_o.error == json_error_unexpected_character &&
		parser_o.bad_byte == parser_o.input) {
		printf ("Failed on first byte with unexpected character.\n");
	    }
	    */
#if 0
	    printf ("Got error: %s\n", parser_o.last_error);
#endif
	    if (parser_o.error == json_error_unexpected_character) {
#if 0
		for (j = 0; j < MAXBYTE; j++) {
		    printf ("%d", parser_o.valid_bytes[j]);
		    if (j % 0x40 == 0x3F) {
			printf ("\n");
		    }
		}
#endif
		/* Alter bytes and run again. */
		alter_one_byte (& parser_o);
		//print_json (& parser_o);
	    }
	    else if (parser_o.error == json_error_empty_input) {
#if 0
		printf ("empty input error.\n");
#endif
		parser_o.bad_byte = parser_o.input;
		alter_one_byte (& parser_o);
#if 0
		printf ("Expanding string to\n");
		print_json (& parser_o);
		printf ("here aga.\n");
#endif
	    }
	    else if (parser_o.error == json_error_unexpected_end_of_input) {
#if 0
		printf ("end of input.\n");
#endif
		parser_o.bad_byte = parser_o.input + json_length - 1;
#if 0
		printf ("Altering final byte.\n");
#endif
		alter_one_byte (& parser_o);
	    }
	    else {
		print_json (& parser_o);
		if (parser_o.error == json_error_second_half_of_surrogate_pair_missing) {
		    printf ("Unfixable error.\n");
		    return;
		}
		fprintf (stderr, "error: %s.\n", parser_o.last_error);
		exit (1);
	    }
	}
	else {
	    c_validate (& parser_o);
	    print_json (& parser_o);
	    printf ("Success in parsing.\n");
	    //	    exit (0);
	    break;
	}
    }
}


int main ()
{
    srandom (time (0));
    random_json ();
    return 0;
}
