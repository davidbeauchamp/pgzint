#ifndef PGZINT_H
#define PGZINT_H

#include <png.h>
#include <zint.h>

// PostgreSQL
#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"

void write_png_data(png_structp png_ptr, png_bytep data, png_size_t length);
unsigned char *uchar_p_from_text_p(text *input);
void validate_and_set_input(text *input, char *dest);
bytea *png_from_barcode(struct zint_symbol *input);

#endif // PGZINT_H
