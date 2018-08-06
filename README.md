# pgzint 0.1.3
=================

PostgreSQL extension for the Zint Barcode library

This extension adds support for generating barcodes via database functions, to allow
any application that can display PNG images to have barcode generation support without
directly integrating with [Zint](http://www.zint.org.uk). The images are returned via a
bytea result.

It primarily adds a function, from pgzint.c:

    bc_generate(
        pinput text,
        psymbology integer,
        pheight integer,
        pscale integer,
        pwhitespacewidth integer,
        pborderwidth integer,
        poutputoptions integer,
        pfgcolor text,
        pbgcolor text,
        pshowtext boolean,
        poption1 integer,
        poption2 integer,
        poption3 integer,
        protation integer = 0
        )

To determine information about what barcode symbologies are available, a table called `bc_symbols` and a view called `barcodes` have been added. Two functions, `getzintsymbolconstant(integer)` and `getzintsymbolid(text)` can be used to look make passing parameters to the barcode generation function easier.

Usage
-----

To generate a QR code with default values:

    SELECT bc_qrcode('SAMPLE');

Which is the  equivalent of calling:

    SELECT bc_generate('SAMPLE', 58, NULL, 2, 0, NULL, NULL, NULL, NULL, NULL, NULL, 14, NULL);

Which uses symbology 58, a scale factor of 2, and value 14 creates a 73x73 image according to [section 6.6.2 of the Zint docs](http://www.zint.org.uk/Manual.aspx?type=p&page=6). I felt these were sane values, always feel free to call `bc_generate` directly with your own choices. `bc_generate` is the only function directly implemented in C, the other convenience functions are just wrappers for `bc_generate` and can be copied using pgAdmin.

Currently implemented convenience functions:

    bc_qrcode(pinput text)
    bc_excode39(pinput text)
    bc_pdf417(pinput text)
    bc_maxicode(pinput text)
    bc_code128(pinput text)

With the rest planned as time allows.

Installation
------------

To build it, just do this:

    make
    make installcheck
    make install

If you encounter an error such as:

    make: pg_config: Command not found

Be sure that you have `pg_config` installed and in your path. If you used a
package management system such as RPM to install PostgreSQL, be sure that the
`-devel` package is also installed. If necessary tell the build process where
to find it:

    env PG_CONFIG=/path/to/pg_config make && make installcheck && make install

If you encounter an error such as:

    ERROR:  must be owner of database contrib_regression

You need to run the test suite using a super user, such as the default
"postgres" super user:

    make installcheck PGUSER=postgres

Once `pgzint` is installed, you can add it to a database. If you're
running PostgreSQL 9.1.0 or greater, it's a simple as connecting to a database
as a super user and running:

    CREATE EXTENSION pgzint;

Dependencies
------------
The `pgzint` extension requires PostgreSQL 9.1 or greater, libzint and libpng. 

Copyright and License
---------------------

pgzint written by David Beauchamp, Released under the MIT license.

libpng [license](http://www.libpng.org/pub/png/src/libpng-LICENSE.txt)

libzint [license](http://www.zint.org.uk/Manual.aspx?type=p&page=7)
