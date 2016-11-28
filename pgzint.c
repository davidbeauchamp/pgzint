#include "pgzint.h"

PG_MODULE_MAGIC;

struct png_memory
{
  char *buffer;
  size_t size;
};

void write_png_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
    struct png_memory* p = (struct png_memory *)png_get_io_ptr(png_ptr);
    size_t newsize = p->size + length;
    if(p->buffer) {
        char *tmpptr = palloc0(newsize);
        memcpy(tmpptr, p->buffer, p->size);
        p->buffer = tmpptr;
    }
    else {
        p->buffer = palloc0(newsize);
    }
  
    if(!p->buffer) {
        ereport(ERROR, (errmsg("Error allocating PNG write buffer.")));
    }
    memcpy(p->buffer + p->size, data, length);
    p->size += length;
}

unsigned char *uchar_p_from_text_p(text *input)
{
    size_t len = VARSIZE(input) - VARHDRSZ;
    unsigned char *new = palloc0(len + 1);
    memcpy(new, VARDATA(input), len);
    new[len] = 0;
    return new;
}

bytea *png_from_barcode(struct zint_symbol *input)
{
    bytea *result;
    png_structp png_ptr = NULL;
    png_infop info_ptr = NULL;
    int x, y, pos = 0;
    png_byte ** row_pointers = NULL;
    int pixel_size = 3;
    int depth = 8;
    struct png_memory image;
    image.buffer = 0;
    image.size = 0;

    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (png_ptr == NULL) {
        return 0;
    }

    info_ptr = png_create_info_struct (png_ptr);
    if (info_ptr == NULL) {
        png_destroy_write_struct (&png_ptr, &info_ptr);
        return 0;
    }

    if (setjmp (png_jmpbuf (png_ptr))) {
        png_destroy_write_struct (&png_ptr, &info_ptr);
        return 0;
    }

    png_set_IHDR(png_ptr,
                 info_ptr,
                 input->bitmap_width,
                 input->bitmap_height,
                 depth,
                 PNG_COLOR_TYPE_RGB,
                 PNG_INTERLACE_NONE,
                 PNG_COMPRESSION_TYPE_DEFAULT,
                 PNG_FILTER_TYPE_DEFAULT);
    
    row_pointers = png_malloc(png_ptr, input->bitmap_height * sizeof (png_byte *));
    for (y = 0; y < input->bitmap_height; y++) {
        png_byte *row = png_malloc(png_ptr, sizeof(uint8_t) * input->bitmap_width * pixel_size);
        row_pointers[y] = row;
        for (x = 0; x < input->bitmap_width; x++) {
            *row++ = input->bitmap[pos];
            *row++ = input->bitmap[pos + 1];
            *row++ = input->bitmap[pos + 2];
            pos += 3;
        }
    }
  
    png_set_write_fn(png_ptr, &image, write_png_data, NULL);
    png_set_rows(png_ptr, info_ptr, row_pointers);
    png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, NULL);

    // free up the memory used by libpng
    for (y = 0; y < input->bitmap_height; y++) {
        png_free(png_ptr, row_pointers[y]);
    }
    png_free(png_ptr, row_pointers);

    result = (bytea *) palloc0(VARHDRSZ + image.size);
    SET_VARSIZE(result, VARHDRSZ + image.size);
    // need to skip the header..
    memcpy(&result[1], image.buffer, image.size);

    return result;
}

PG_FUNCTION_INFO_V1(bc_generate);
Datum
bc_generate(PG_FUNCTION_ARGS)
{
    bytea *result;
    struct zint_symbol *barcode;
    unsigned char *input;
    int error = 0;
    barcode = ZBarcode_Create();
    barcode->input_mode = UNICODE_MODE;

    if (PG_ARGISNULL(0))
        ereport(ERROR, (errmsg("Error creating barcode"),
                        errdetail("No input provided"),
                        errhint("Input is required to generate a barcode")));
    else
       input = uchar_p_from_text_p(PG_GETARG_TEXT_P(0));

    if (!PG_ARGISNULL(1))
        barcode->symbology = PG_GETARG_INT32(1);

    if (!PG_ARGISNULL(2))
        barcode->height = PG_GETARG_INT32(2);

    if (!PG_ARGISNULL(3))
        barcode->scale = PG_GETARG_INT32(3);

    if (!PG_ARGISNULL(4))
        barcode->whitespace_width = PG_GETARG_INT32(4);

    if (!PG_ARGISNULL(5))
        barcode->border_width = PG_GETARG_INT32(5);

    if (!PG_ARGISNULL(6))
        barcode->output_options = PG_GETARG_INT32(6);

    if (!PG_ARGISNULL(7))
        strcpy(barcode->fgcolour, VARDATA(PG_GETARG_TEXT_P(7)));
    else
        strcpy(barcode->fgcolour, "000000");

    if (!PG_ARGISNULL(8))
        strcpy(barcode->bgcolour, VARDATA(PG_GETARG_TEXT_P(8)));
    else
        strcpy(barcode->bgcolour, "FFFFFF");

    if (!PG_ARGISNULL(9) && PG_GETARG_BOOL(9))
        barcode->show_hrt = 1;
    else
        barcode->show_hrt = 0;

    if (!PG_ARGISNULL(10))
        barcode->option_1 = PG_GETARG_INT32(10);

    if (!PG_ARGISNULL(11))
        barcode->option_2 = PG_GETARG_INT32(11);

    if (!PG_ARGISNULL(12))
        barcode->option_3 = PG_GETARG_INT32(12);

    error = ZBarcode_Encode_and_Buffer(barcode, input, 0, 0);

    if (error >= ZWARN_INVALID_OPTION)
    {
        ereport(ERROR, (errmsg("%s", barcode->errtxt)));
        ZBarcode_Delete(barcode);
        PG_RETURN_NULL();
    }
    
    result = png_from_barcode(barcode);
    ZBarcode_Delete(barcode);
    PG_RETURN_BYTEA_P(result);
}
