#define DEBUG_AUTHNICE 0

#define DEBUGCODE(x) fprintf(stderr, "Return code is %i\n", (x))

#if DEBUG_AUTHNICE >= 1
#define debug_print(x) NSLog(@x)
#else
#define debug_print(x)
#endif
