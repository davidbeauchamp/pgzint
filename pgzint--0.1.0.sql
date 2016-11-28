\echo Use "CREATE EXTENSION pgzint" to load this file. \quit

/* primary functions */
CREATE FUNCTION bc_generate(pinput text,
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
                            poption3 integer                            
                )
RETURNS bytea
AS '$libdir/pgzint'
LANGUAGE C IMMUTABLE;

CREATE FUNCTION bc_qrcode(pinput text)
RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
  BEGIN
    RETURN(bc_generate(pinput, 58, NULL, 2, 0, NULL, NULL, NULL, NULL, NULL, NULL, 14, NULL));
  END;
$$;

CREATE FUNCTION bc_excode39(pinput text)
RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
  BEGIN
    RETURN(bc_generate(pinput, 9, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL));
  END;
$$;

CREATE FUNCTION bc_pdf417(pinput text)
RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
  BEGIN
    RETURN(bc_generate(pinput, 55, NULL, 3, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 928));
  END;
$$;

CREATE FUNCTION bc_maxicode(pinput text)
RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
  BEGIN
    RETURN(bc_generate(pinput, 57, 33, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL));
  END;
$$;

CREATE FUNCTION bc_code128(pinput text)
RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
  BEGIN
    RETURN(bc_generate(pinput, 20, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL));
  END;
$$;

/* table to store barcode symbol information */
CREATE TABLE public.bc_symbols
(
  bc_symbol_id serial,
  bc_symbol_zint_id integer, -- ID of the Barcode from zint.h
  bc_symbol_zint_constant text, -- Defined constant of the Barcode from zint.h
  bc_symbol_name text, -- Name of the Barcode
  bc_symbol_dim integer, -- DImenions of the symbol. Valid values are 1, 2 and 3.
  bc_symbol_minlength integer, -- Minimum length of input, or 0 if no minimum.
  bc_symbol_maxlength integer, -- Maximum length of input, or 0 if no maximum.
  bc_symbol_numeric boolean, -- Whether or not the input is numerical only.
  bc_symbol_parity boolean, -- Whether or not the barcode supports parity/security
  bc_symbol_checkdigit boolean, -- Whether or not the barcode supports a check digit
  bc_symbol_notes text, -- Notes about the symbol from the Zint documentation on http://www.zint.org.uk/Manual.aspx?type=p&page=6
  CONSTRAINT bc_symbol_id_pk PRIMARY KEY (bc_symbol_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.bc_symbols
  OWNER TO postgres;
COMMENT ON COLUMN public.bc_symbols.bc_symbol_zint_id IS 'ID of the Barcode from zint.h';
COMMENT ON COLUMN public.bc_symbols.bc_symbol_name IS 'Name of the Barcode';
COMMENT ON COLUMN public.bc_symbols.bc_symbol_dim IS 'DImenions of the symbol. Valid values are 1, 2 and 3.';
COMMENT ON COLUMN public.bc_symbols.bc_symbol_minlength IS 'Minimum length of input, or 0 if no minimum. ';
COMMENT ON COLUMN public.bc_symbols.bc_symbol_maxlength IS 'Maximum length of input, or 0 if no maximum.';
COMMENT ON COLUMN public.bc_symbols.bc_symbol_numeric IS 'Whether or not the input is numerical only.';
COMMENT ON COLUMN public.bc_symbols.bc_symbol_parity IS 'Whether or not the barcode supports parity/security';
COMMENT ON COLUMN public.bc_symbols.bc_symbol_checkdigit IS 'Whether or not the barcode supports a check digit';
COMMENT ON COLUMN public.bc_symbols.bc_symbol_notes IS 'Notes about the symbol from the Zint documentation on http://www.zint.org.uk/Manual.aspx?type=p&page=6';

/*
  Convenience view to get info from barcode table
*/
CREATE OR REPLACE VIEW public.barcodes AS
 SELECT
    bc_symbols.bc_symbol_zint_id,
    bc_symbols.bc_symbol_zint_constant,
    bc_symbols.bc_symbol_name,
    bc_symbols.bc_symbol_dim,
    bc_symbols.bc_symbol_minlength,
    bc_symbols.bc_symbol_maxlength,
    bc_symbols.bc_symbol_numeric,
    bc_symbols.bc_symbol_parity,
    bc_symbols.bc_symbol_checkdigit,
    bc_symbols.bc_symbol_notes
   FROM bc_symbols;

ALTER TABLE public.barcodes
  OWNER TO postgres;
GRANT ALL ON TABLE public.barcodes TO postgres;
GRANT SELECT ON TABLE public.barcodes TO public;

/*
  Convenience function to get symbol id from the defined constant
*/
CREATE OR REPLACE FUNCTION public.getzintsymbolid(pZintConstant text)
  RETURNS integer AS
$$
DECLARE
  _result INTEGER;
BEGIN
  IF (pZintConstant IS NULL) THEN
    RETURN NULL;
  END IF;

  SELECT bc_symbol_zint_id INTO _result
  FROM bc_symbols
  WHERE (bc_symbol_zint_constant=pZintConstant);

  IF (_result IS NULL) THEN
    RAISE EXCEPTION 'Barcode % was not found.', pZintConstant;
  END IF;

  RETURN _result;
END;
$$
  LANGUAGE plpgsql STABLE;
ALTER FUNCTION public.getzintsymbolid(text)
  OWNER TO postgres;

/*
  Convenience function to get the symbol constant from the defined id
*/
CREATE OR REPLACE FUNCTION public.getzintsymbolconstant(pZintId integer)
  RETURNS text AS
$$
DECLARE
  _result TEXT;
BEGIN
  IF (pZintId IS NULL) THEN
    RETURN NULL;
  END IF;

  SELECT bc_symbol_zint_constant INTO _result
  FROM bc_symbols
  WHERE (bc_symbol_zint_id=pZintId);

  IF (_result IS NULL) THEN
    RAISE EXCEPTION 'Barcode ID % was not found.', pZintId;
  END IF;

  RETURN _result;
END;
$$
  LANGUAGE plpgsql STABLE;
ALTER FUNCTION public.getzintsymbolconstant(integer)
  OWNER TO postgres;

/*
  Default data for the bc_symbols table
*/
INSERT INTO bc_symbols VALUES (1,  1,   'BARCODE_CODE11', 'Code 11', 1, 0, 0, true, false, true, NULL);
INSERT INTO bc_symbols VALUES (2,  2,   'BARCODE_C25MATRIX', 'Code 2 of 5', 1, 0, 0, true, false, false, NULL);
INSERT INTO bc_symbols VALUES (3,  3,   'BARCODE_C25INTER', 'Code 2 of 5 Interleaved', 1, 0, 0, true, false, false, NULL);
INSERT INTO bc_symbols VALUES (4,  4,   'BARCODE_C25IATA', NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (5,  6,   'BARCODE_C25LOGIC', NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (6,  7,   'BARCODE_C25IND', NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (7,  8,   'BARCODE_CODE39', 'Code 39', 1, 0, 0, false, false, true, NULL);
INSERT INTO bc_symbols VALUES (8,  9,   'BARCODE_EXCODE39', 'Code 39+', 1, 0, 0, false, false, true, NULL);
INSERT INTO bc_symbols VALUES (9,  13,  'BARCODE_EANX', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (10, 16,  'BARCODE_EAN128', NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (11, 18,  'BARCODE_CODABAR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (12, 20,  'BARCODE_CODE128', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (13, 21,  'BARCODE_DPLEIT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (14, 22,  'BARCODE_DPIDENT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (15, 23,  'BARCODE_CODE16K', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (16, 24,  'BARCODE_CODE49', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (17, 25,  'BARCODE_CODE93', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (18, 28,  'BARCODE_FLAT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (19, 29,  'BARCODE_RSS14', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (20, 30,  'BARCODE_RSS_LTD', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (21, 31,  'BARCODE_RSS_EXP', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (22, 32,  'BARCODE_TELEPEN', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (23, 34,  'BARCODE_UPCA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (24, 37,  'BARCODE_UPCE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (25, 40,  'BARCODE_POSTNET', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (26, 47,  'BARCODE_MSI_PLESSEY', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (27, 49,  'BARCODE_FIM', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (28, 50,  'BARCODE_LOGMARS', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (29, 51,  'BARCODE_PHARMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (30, 52,  'BARCODE_PZN', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (31, 53,  'BARCODE_PHARMA_TWO', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (33, 56,  'BARCODE_PDF417TRUNC', 'PDF417 Compact', 2, 1, 1850, false, true, false, NULL);
INSERT INTO bc_symbols VALUES (32, 55,  'BARCODE_PDF417', 'PDF417', 2, 1, 1850, false, true, false, NULL);
INSERT INTO bc_symbols VALUES (35, 58,  'BARCODE_QRCODE', 'QR Code', 2, 1, 4296, false, true, false, NULL);
INSERT INTO bc_symbols VALUES (34, 57,  'BARCODE_MAXICODE', 'Maxicode', 2, 1, 15, true, true, false, NULL);
INSERT INTO bc_symbols VALUES (36, 60,  'BARCODE_CODE128B', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (37, 63,  'BARCODE_AUSPOST', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (38, 66,  'BARCODE_AUSREPLY', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (39, 67,  'BARCODE_AUSROUTE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (40, 68,  'BARCODE_AUSREDIRECT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (41, 69,  'BARCODE_ISBNX', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (42, 70,  'BARCODE_RM4SCC', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (43, 71,  'BARCODE_DATAMATRIX', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (44, 72,  'BARCODE_EAN14', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (45, 74,  'BARCODE_CODABLOCKF', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (46, 75,  'BARCODE_NVE18', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (47, 76,  'BARCODE_JAPANPOST', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (48, 77,  'BARCODE_KOREAPOST', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (49, 79,  'BARCODE_RSS14STACK', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (50, 80,  'BARCODE_RSS14STACK_OMNI', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (51, 81,  'BARCODE_RSS_EXPSTACK', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (52, 82,  'BARCODE_PLANET', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (53, 84,  'BARCODE_MICROPDF417', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (54, 85,  'BARCODE_ONECODE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (55, 86,  'BARCODE_PLESSEY', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (56, 87,  'BARCODE_TELEPEN_NUM', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (57, 89,  'BARCODE_ITF14', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (58, 90,  'BARCODE_KIX', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (59, 92,  'BARCODE_AZTEC', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (60, 93,  'BARCODE_DAFT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (61, 97,  'BARCODE_MICROQR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (62, 98,  'BARCODE_HIBC_128', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (63, 99,  'BARCODE_HIBC_39', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (64, 102, 'BARCODE_HIBC_DM', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (65, 104, 'BARCODE_HIBC_QR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (66, 106, 'BARCODE_HIBC_PDF', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (67, 108, 'BARCODE_HIBC_MICPDF', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (68, 110, 'BARCODE_HIBC_BLOCKF', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols VALUES (69, 112, 'BARCODE_HIBC_AZTEC', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
