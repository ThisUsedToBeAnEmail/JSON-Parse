#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* TESTRANDOM should never be defined in the code released to
   CPAN. This is tested in "xt/testrandom-invalid.t". */

//#define TESTRANDOM

#ifdef TESTRANDOM
#include <setjmp.h>
#endif /* def TESTRANDOM */

static SV * json_null;

/* Code starts here. */

#include "unicode.h"
#include "unicode.c"
#include "json-common.c"
#define PERLING
#include "json-perl.c"
#undef PERLING
#define TOKENING
#include "json-perl.c"
#undef TOKENING
#include "json-perl.c"
#include "json-entry-points.c"
#ifdef TESTRANDOM
#include "json-random-test.c"
#endif /* def TESTRANDOM */
#include "json-whitespace.c"
#ifdef NOPERL
#error "Cannot define NOPERL error when compiling Perl version"
#endif /* def NOPERL */

typedef json_parse_t * JSON__Parse;
typedef json_token_t * JSON__Tokenize;

MODULE=JSON::Parse PACKAGE=JSON::Parse

PROTOTYPES: DISABLE
BOOT:
{
       json_null = get_sv ("JSON::Parse::null", GV_ADD);
       SvREADONLY_on (json_null);
}

SV * parse_json (json)
	SV * json;
CODE:
	RETVAL = parse (json);
OUTPUT:
	RETVAL

SV * parse_json_safer (json)
	SV * json;
CODE:
	RETVAL = parse_safe (json);
OUTPUT:
	RETVAL

void assert_valid_json (json)
	SV * json;
CODE:
	validate (json, 0);

JSON::Parse
new (char * class, ...)
CODE:
	if (! class) {
	    croak ("no class");
	}
	Newxz (RETVAL, 1, json_parse_t);
OUTPUT:
	RETVAL

SV * run_internal (parser, json)
	JSON::Parse parser
	SV * json
CODE:
	RETVAL = json_parse_run (parser, json);
OUTPUT:
	RETVAL

void
DESTROY (parser)
	JSON::Parse parser;
CODE:
	json_parse_free (parser);

void
set_true (parser, user_true)
	JSON::Parse parser;
	SV * user_true;
CODE:
	json_parse_set_true (parser, user_true);

void
set_false (parser, user_false)
	JSON::Parse parser;
	SV * user_false;
CODE:
	json_parse_set_false (parser, user_false);

void
set_null (parser, user_null)
	JSON::Parse parser;
	SV * user_null;
CODE:
	json_parse_set_null (parser, user_null);

void
delete_true (parser)
	JSON::Parse parser;
CODE:
	json_parse_delete_true (parser);

void
delete_false (parser)
	JSON::Parse parser;
CODE:
	json_parse_delete_false (parser);

void
delete_null (parser)
	JSON::Parse parser;
CODE:
	json_parse_delete_null (parser);

void
copy_literals (parser, onoff)
	JSON::Parse parser;
	SV * onoff;
CODE:
	json_parse_copy_literals (parser, onoff);

void
no_warn_literals (parser, onoff)
	JSON::Parse parser;
	SV * onoff;
CODE:
	parser->no_warn_literals = SvTRUE (onoff) ? 1 : 0;

void
diagnostics_hash (parser, onoff)
	JSON::Parse parser;
	SV * onoff;
CODE:
#if PERL_VERSION > 12
	parser->diagnostics_hash = SvTRUE (onoff) ? 1 : 0;
#else
        vwarn ("diagnostics_hash () requires Perl 5.14 or later; this is 5.%d",
	       PERL_VERSION);
#endif

void
warn_only (parser, onoff)
	JSON::Parse parser;
	SV * onoff;
CODE:
	parser->warn_only = SvTRUE (onoff) ? 1 : 0;

int
get_warn_only (parser)
	JSON::Parse parser;
CODE:
	if (parser->warn_only) {
		RETVAL = 1;
	}
	else {
		RETVAL = 0;
	}
OUTPUT:
	RETVAL


void
detect_collisions (parser, onoff)
	JSON::Parse parser;
	SV * onoff;
CODE:
	parser->detect_collisions = SvTRUE (onoff) ? 1 : 0;

#ifdef TESTRANDOM

int random_json ()
CODE:
	RETVAL = random_json ();
OUTPUT:
	RETVAL

#endif /* def TESTRANDOM */

MODULE=JSON::Parse PACKAGE=JSON::Tokenize

SV * tokenize_json (json)
	SV * json;
CODE:
	RETVAL = newSViv ((IV) tokenize (json));
OUTPUT:
	RETVAL

SV * tokenize_child (svtoken)
 	SV * svtoken
PREINIT:
	json_token_t * token;
CODE:
	token = (json_token_t *) SvIV (svtoken);
	if (token && token->child) {
	    RETVAL = newSViv ((IV) token->child);
	}
	else {
	    RETVAL = & PL_sv_undef;
	}
OUTPUT:
    	RETVAL

SV * tokenize_next (svtoken)
 	SV * svtoken
PREINIT:
	json_token_t * token;
CODE:
	token = (json_token_t *) SvIV (svtoken);
	if (token && token->next) {
	    RETVAL = newSViv ((IV) token->next);
	}
	else {
	    RETVAL = & PL_sv_undef;
	}
OUTPUT:
    	RETVAL

SV * tokenize_start (svtoken)
 	SV * svtoken
PREINIT:
	json_token_t * token;
CODE:
	token = (json_token_t *) SvIV (svtoken);
	if (token) {
		RETVAL = newSViv (token->start);
	}
	else {
	    RETVAL = & PL_sv_undef;
	}
OUTPUT:
    	RETVAL

SV * tokenize_end (svtoken)
 	SV * svtoken
PREINIT:
	json_token_t * token;
CODE:
	token = (json_token_t *) SvIV (svtoken);
	if (token) {
		RETVAL = newSViv (token->end);
	}
	else {
	    RETVAL = & PL_sv_undef;
	}
OUTPUT:
    	RETVAL

SV * tokenize_type (svtoken)
 	SV * svtoken
PREINIT:
	json_token_t * token;
CODE:
	token = (json_token_t *) SvIV (svtoken);
	/* Only set this to the real value if everything is OK. */
	RETVAL = & PL_sv_undef;
        if (token) {
	    if (token->type > json_token_invalid &&
		token->type < n_json_tokens) {
		RETVAL = newSVpv (token_names[token->type], 0);
	    }
	    else {
		warn ("Invalid JSON token type %d", token->type);
	    }
	}
OUTPUT:
	RETVAL

void DESTROY (tokens)
	json_token_t * tokens;
CODE:
	tokenize_free (tokens);

MODULE=JSON::Parse PACKAGE=JSON::Whitespace

SV * strip_whitespace (tokens, json)
	JSON::Tokenize tokens;
	SV * json;
CODE:
	RETVAL = strip_whitespace (tokens, json);
OUTPUT:
	RETVAL

