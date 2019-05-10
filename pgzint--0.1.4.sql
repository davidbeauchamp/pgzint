\echo Use "CREATE EXTENSION pgzint" to load this file. \quit

/* primary functions */
CREATE OR REPLACE FUNCTION bc_generate(
  pinput text,
  psymbology integer,
  pheight integer,
  pscale float8,
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
RETURNS bytea
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION bc_qrcode(pinput text)
RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
  BEGIN
    RETURN(bc_generate(pinput, 58, NULL, 2, 0, NULL, NULL, NULL, NULL, NULL, NULL, 14, NULL, 0));
  END;
$$;

CREATE OR REPLACE FUNCTION bc_excode39(pinput text)
RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
  BEGIN
    RETURN(bc_generate(pinput, 9, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0));
  END;
$$;

CREATE OR REPLACE FUNCTION bc_pdf417(pinput text)
RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
  BEGIN
    RETURN(bc_generate(pinput, 55, NULL, 3, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 928, 0));
  END;
$$;

CREATE OR REPLACE FUNCTION bc_maxicode(pinput text)
RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
  BEGIN
    RETURN(bc_generate(pinput, 57, 33, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0));
  END;
$$;

CREATE OR REPLACE FUNCTION bc_code128(pinput text)
RETURNS bytea
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
  BEGIN
    RETURN(bc_generate(pinput, 20, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0));
  END;
$$;

CREATE OR REPLACE FUNCTION pgzint_version()
RETURNS TEXT
LANGUAGE plpgsql STABLE
AS $$
  BEGIN
    RETURN '0.1.4';
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
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (16, 24, 'BARCODE_CODE49', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (18, 28, 'BARCODE_FLAT', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (19, 29, 'BARCODE_RSS14', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (20, 30, 'BARCODE_RSS_LTD', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (21, 31, 'BARCODE_RSS_EXP', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (22, 32, 'BARCODE_TELEPEN', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (26, 47, 'BARCODE_MSI_PLESSEY', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (27, 49, 'BARCODE_FIM', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (29, 51, 'BARCODE_PHARMA', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (31, 53, 'BARCODE_PHARMA_TWO', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (46, 75, 'BARCODE_NVE18', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (49, 79, 'BARCODE_RSS14STACK', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (50, 80, 'BARCODE_RSS14STACK_OMNI', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (51, 81, 'BARCODE_RSS_EXPSTACK', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (55, 86, 'BARCODE_PLESSEY', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (56, 87, 'BARCODE_TELEPEN_NUM', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (57, 89, 'BARCODE_ITF14', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (60, 93, 'BARCODE_DAFT', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (61, 97, 'BARCODE_MICROQR', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (62, 98, 'BARCODE_HIBC_128', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (64, 102, 'BARCODE_HIBC_DM', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (65, 104, 'BARCODE_HIBC_QR', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (66, 106, 'BARCODE_HIBC_PDF', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (67, 108, 'BARCODE_HIBC_MICPDF', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (68, 110, 'BARCODE_HIBC_BLOCKF', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (69, 112, 'BARCODE_HIBC_AZTEC', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (33, 56, 'BARCODE_PDF417TRUNC', 'PDF417 Compact', 2, 1, false, true, false, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (32, 55, 'BARCODE_PDF417', 'PDF417', 2, 1, false, true, false, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (10, 16, 'BARCODE_EAN128', 'EAN-128 or GSI-128', 1, 1, false, false, false, 'A variation of Code 128 also known as UCC/EAN-128, this symbology is defined by the GS1 General Specification. Application Identifiers (AIs) should be entered using [square bracket] notation. These will be converted to (round brackets) for the human readable text. This will allow round brackets to be used in the data strings to be encoded. Fixed length data should be entered at the appropriate length for correct encoding (see Appendix C). GS1-128 does not support extended ASCII characters. Check digits for GTIN data (AI 01) are not generated and need to be included in the input data.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (8, 9, 'BARCODE_EXCODE39', 'Code 39+', 1, 1, false, false, true, 'Also known as Code 39e and Code39+, this symbology expands on Standard Code 39 to provide support to the full ASCII character set. The standard does not require a check digit but a modulo-43 check digit can be added if required by setting option_2 = 1');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (36, 60, 'BARCODE_CODE128B', 'Code 128 Subset B', 1, 1, false, false, false, 'It is sometimes advantageous to stop Code 128 from using subset mode C which compresses numerical data. The BARCODE_CODE128B option (symbology 60) suppresses mode C in favour of mode B.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (28, 50, 'BARCODE_LOGMARS', 'LOGMARS', 1, 1, false, false, true, 'LOGMARS (Logistics Applications of Automated Marking and Reading symbols) is a variation of the Code 39 symbology used by the US Department of Defence. LOGMARS encodes the same character set as Standard Code 39 and adds a modulo-43 check digit.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (17, 25, 'BARCODE_CODE93', 'Code 93', 1, 1, false, false, true, 'A variation of Extended Code 39, Code 93 also supports full ASCII text. Two check digits are added by Zint.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (30, 52, 'BARCODE_PZN', 'PZN', 1, 6, true, false, true, 'PZN is a Code 39 based symbology used by the pharmaceutical industry in Germany. PZN encodes a 6 digit number to which Zint will add a modulo-10 check digit.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (4, 4, 'BARCODE_C25IATA', 'Code 2 of 5 IATA', 1, 1, true, false, false, 'Used for baggage handling in the air-transport industry by the International Air Transport Agency, this self-checking code will encode any length numeric input (digits 0-9) and does not include a check digit.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (3, 3, 'BARCODE_C25INTER', 'Code 2 of 5 Interleaved', 1, 1, true, false, false, 'This self-checking symbology encodes pairs of numbers, and so can only encode an even number of digits (0-9). If an odd number of digits is entered a leading zero is added by Zint. No check digit is added.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (2, 2, 'BARCODE_C25MATRIX', 'Code 2 of 5', 1, 1, true, false, false, 'Also known as Code 2 of 5 Matrix is a self-checking code used in industrial applications and photo development. Standard Code 2 of 5 will encode any length numeric input (digits 0-9).');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (1, 1, 'BARCODE_CODE11', 'Code 11', 1, 1, true, false, true, 'Developed by Intermec in 1977, Code 11 is similar to Code 2 of 5 Matrix and is primarily used in telecommunications. The symbol can encode any length string consisting of the digits 0-9 and the dash character (-). One modulo-11 check digit is calculated.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (48, 77, 'BARCODE_KOREAPOST', 'Korea Post', 1, 6, false, false, true, 'The Korean Postal Barcode is used to encode a six-digit number and includes one check digit.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (38, 66, 'BARCODE_AUSREPLY', 'Australia Post Reply', 1, 1, false, false, false, 'A Reply Paid version of the Australia Post 4-State Barcode (FCC 45) which requires an 8-digit DPID input.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (13, 21, 'BARCODE_DPLEIT', NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (14, 22, 'BARCODE_DPIDENT', NULL, NULL, 1, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (5, 6, 'BARCODE_C25LOGIC', 'Code 2 of 5 Data Logic', 1, 1, true, false, false, 'Data Logic does not include a check digit and can encode any length numeric input (digits 0-9).');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (6, 7, 'BARCODE_C25IND', 'Code 2 of 5 Industrial', 1, 1, true, false, false, 'Industrial Code 2 of 5 can encode any length numeric input (digits 0-9) and does not include a check digit.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (7, 8, 'BARCODE_CODE39', 'Code 39', 1, 1, false, false, true, 'Standard Code 39 was developed in 1974 by Intermec. Input data can be of any length and can include the characters 0-9, A-Z, dash (-), full stop (.), space, asterisk (*), dollar ($), slash (/), plus (+) and percent (%). The standard does not require a check digit but a modulo-43 check digit can be added if required by setting option_2 = 1');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (39, 67, 'BARCODE_AUSROUTE', 'Australia Post Routing', 1, 1, false, false, false, 'A Routing version of the Australia Post 4-State Barcode (FCC 87) which requires an 8-digit DPID input.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (63, 99, 'BARCODE_HIBC_39', 'HIBC Code 39', 1, 1, false, false, true, 'This option adds a leading ''+'' character and a trailing modulo-49 check digit to a standard Code 39 symbol as required by the Health Industry Barcode standards.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (40, 68, 'BARCODE_AUSREDIRECT', 'Australia Post Redirect', 1, 1, false, false, false, 'A Redirection version of the Australia Post 4-State Barcode (FCC 92) which requires an 8-digit DPID input.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (70, 128, 'BARCODE_AZRUNE', 'Aztec Runes', 2, 1, true, false, false, 'A truncated version of compact Aztec Code for encoding whole integers between 0 and 255. Includes Reed-Solomon error correction. As defined in ISO/IEC 24778 Annex A.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (58, 90, 'BARCODE_KIX', 'Dutch Post KIX Code', 1, 11, true, false, false, 'This symbology is used by Royal Dutch TPG Post (Netherlands) for Postal code and automatic mail sorting. Data input can consist of numbers 0-9 and letters A-Z and needs to be 11 characters in length. No check digit is included.
');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (71, 129, 'BARCODE_CODE32', 'Code 32', 1, 1, false, false, true, 'A variation of Code 39 used by the Italian Ministry of Health ("Ministero della Sanità") for encoding identifiers on pharmaceutical products. for encoding identifiers on pharmaceutical products. This symbology requires a numeric input up to 8 digits in length. A check digit is added by Zint.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (9, 13, 'BARCODE_EANX', 'EAN Extended', 1, 1, false, false, true, 'The EAN system is used in retail across Europe and includes standards for EAN-2 and EAN-5 add-on codes, EAN-8 and EAN-13 which encode 2, 5, 7 or 12 digit numbers respectively. Zint will decide which symbology to use depending on the length of the input data. In addition EAN-2 and EAN-5 add-on symbols can be added using the + symbol as with UPC symbols. For example:
zint --barcode=13 -d 54321
will encode a stand-alone EAN-5, whereas
zint --barcode=13 -d 7432365+54321
will encode an EAN-8 symbol with an EAN-5 add-on. As before these results can be achieved using the API:
my_symbol->symbology = BARCODE_EANX;
error = ZBarcode_Encode_and_Print(my_symbol, "54321");
error = ZBarcode_Encode_and_Print(my_symbol, "7432365+54321");
All of the EAN symbols include check digits which is added by Zint.
If you are encoding an EAN-8 or EAN-13 symbol and your data already includes the check digit then you can use symbology 14 which takes an 8 or 13 digit input and validates the check digit before encoding.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (11, 18, 'BARCODE_CODABAR', 'Codabar (EN 798)', 1, 1, false, false, false, 'Also known as NW-7, Monarch, ABC Codabar, USD-4, Ames Code and Code 27, this symbology was developed in 1972 by Monarch Marketing Systems for retail purposes. The American Blood Commission adopted Codabar in 1977 as the standard symbology for blood identification. Codabar can encode any length string starting and ending with the letters A-D and containing between these letters the numbers 0-9, dash (-), dollar ($), colon (:), slash (/), full stop (.) or plus (+). No check digit is generated.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (12, 20, 'BARCODE_CODE128', 'Code 128', 1, 1, false, false, false, 'One of the most ubiquitous one-dimensional barcode symbologies, Code 128 was developed in 1981 by Computer Identics. This symbology supports full ASCII text and uses a three-mode system to compress the data into a smaller symbol. Zint automatically switches between modes and adds a modulo-103 check digit. Code 128 is the default barcode symbology used by Zint. In addition Zint supports the encoding of Latin-1 (non-English) characters in Code 128 symbols');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (44, 72, 'BARCODE_EAN14', 'EAN-14', 1, 13, false, false, true, 'A shorter version of GS1-128 which encodes GTIN data only. A 13 digit number is required. The GTIN check digit and AI (01) are added by Zint.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (45, 74, 'BARCODE_CODABLOCKF', 'Codablock-F', 1, 1, false, false, false, 'This is a stacked symbology based on Code 128 which can encode ASCII code set data up to a maximum length of 2725 characters. The width of the Codablock-F symbol can be set using the --cols= option at the command line or option_2. Alternatively the height (number of rows) can be set using the --rows= option at the command line or by setting option_1. Zint does not support encoding of GS1 data in Codablock-F symbols.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (15, 23, 'BARCODE_CODE16K', 'Code 16k (EN 12323)', 1, 1, false, false, true, 'Code 16k uses a Code 128 based system which can stack up to 16 rows in a block. This gives a maximum data capacity of 77 characters or 154 numerical digits and includes two modulo-107 check digits. Code 16k also supports extended ASCII character encoding in the same manner as Code 128.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (53, 84, 'BARCODE_MICROPDF417', 'MicroPDF417 (ISO 24728)', 2, 1, false, true, true, 'A variation of the PDF417 standard, MicroPDF417 is intended for applications where symbol size needs to be kept to a minimum. 34 predefined symbol sizes are available with 1 - 4 columns and 4 - 44 rows. The maximum size MicroPDF417 symbol can hold 250 alphanumeric characters or 366 digits. The amount of error correction used is dependent on symbol size. The number of columns used can be determined using the --cols switch or option_2 as with PDF417. This symbology uses Latin-1 character encoding by default but also supports the ECI encoding mechanism. A separate symbology ID can be used to encode Health Industry Barcode (HIBC) data which adds a leading ''+'' character and a modulo-49 check digit to the encoded data.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (25, 40, 'BARCODE_POSTNET', 'PostNet', 1, 1, true, false, false, 'Used by the United States Postal Service until 2009, the PostNet barcode was used for encoding zip-codes on mail items. PostNet uses numerical input data and includes a modulo-10 check digit. While Zint will encode PostNet symbols of any length, standard lengths as used by USPS were PostNet6 (5 digits ZIP input), PostNet10 (5 digit ZIP + 4 digit user data) and PostNet12 (5 digit ZIP + 6 digit user data).');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (52, 82, 'BARCODE_PLANET', 'PLANET', 1, 1, true, false, false, 'Used by the United States Postal Service until 2009, the PLANET (Postal Alpha Numeric Encoding Technique) barcode was used for encoding routing data on mail items. Planet uses numerical input data and includes a modulo-10 check digit. While Zint will encode PLANET symbols of any length, standard lengths used by USPS were Planet12 (11 digit input) and Planet14 (13 digit input).');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (37, 63, 'BARCODE_AUSPOST', 'Australia Post', 1, 1, false, false, false, 'Australia Post Standard Customer Barcode, Customer Barcode 2 and Customer Barcode 3 are 37-bar, 52-bar and 67-bar specifications respectively, developed by Australia Post for printing Delivery Point ID (DPID) and customer information on mail items. Valid data characters are 0-9, A-Z, a-z, space and hash (#). A Format Control Code (FCC) is added by Zint and should not be included in the input data. Reed-Solomon error correction data is generated by Zint. Encoding behaviour is determined by the length of the input data according to the formula shown in the following table:
Input Length Required Input Format   symbol Length FCC Encoding Table
8            99999999                37-bar        11  None
13           99999999AAAAA           52-bar        59  C
16           9999999999999999        52-bar        59  N
18           99999999AAAAAAAAAA      67-bar        62  C
23           99999999999999999999999 67-bar        62  N');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (42, 70, 'BARCODE_RM4SCC', 'Royal Mail 4-State Country Code (RM4SCC)', 1, 1, false, false, true, 'The RM4SCC standard is used by the Royal Mail in the UK to encode postcode and customer data on mail items. Data input can consist of numbers 0-9 and letters A-Z and usually includes delivery postcode followed by house number. For example "W1J0TR01" for 1 Picadilly Circus in London. Check digit data is generated by Zint.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (54, 85, 'BARCODE_ONECODE', 'USPS OneCode', 1, 1, false, false, false, 'Also known as the Intelligent Mail Barcode and used in the US by the United States Postal Service (USPS), the OneCode system replaced the PostNet and PLANET symbologies in 2009. OneCode is a fixed length (65-bar) symbol which combines routing and customer information in a single symbol. Input data consists of a 20 digit tracking code, followed by a dash (-), followed by a delivery point zip-code which can be 0, 5, 9 or 11 digits in length. For example all of the following inputs are valid data entries:
"01234567094987654321"
"01234567094987654321-01234"
"01234567094987654321-012345678"
"01234567094987654321-01234567891"');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (47, 76, 'BARCODE_JAPANPOST', 'Japanese Postal Code', 1, 1, false, false, true, 'Used for address data on mail items for Japan Post. Accepted values are 0-9, A-Z and Dash (-). A modulo 19 check digit is added by Zint.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (41, 69, 'BARCODE_ISBNX', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (43, 71, 'BARCODE_DATAMATRIX', 'Data Matrix ECC200 (ISO 16022)', 2, 1, false, true, true, 'Also known as Semacode this symbology was developed in 1989 by Acuity CiMatrix in partnership with the US DoD and NASA. The symbol can encode a large amount of data in a small area. characters in the Latin-1 set by default but also supports encoding using other character sets using the ECI mechanism. It can also encode GS1 data. The size of the generated symbol can also be adjusted using the --vers= option or by setting option_2 as shown in the table below. A separate symbology ID can be used to encode Health Industry Barcode (HIBC) data which adds a leading ''+'' character and a modulo-49 check digit to the encoded data. Note that only ECC200 encoding is supported, the older standards have now been removed from Zint.
Input
symbol Size
Input
symbol Size
1
10 x 10
16
64 x 64
2
12 x 12
17
72 x 72
3
14 x 14
18
80 x 80
4
16 x 16
19
88 x 88
5
18 x 18
20
96 x 96
6
20 x 20
21
104 x 104
7
22 x 22
22
120 x 120
8
24 x 24
23
132 x 132
9
26 x 26
24
144 x 144
10
32 x 32
25
8 x 18
11
36 x 36
26
8 x 32
12
40 x 40
27
12 x 26
13
44 x 44
28
12 x 36
14
48 x 48
29
16 x 36
15
52 x 52
30
16 x 48
To force Zint only to use square symbols (versions 1-24) at the command line use the option --square and when using the API set the value option_3 = DM_SQUARE.
Data Matrix Rectangular Extension (DMRE) may be generated with the following values as before.
Input
symbol Size
Input
symbol Size
31
8 x 48
37
24 x 48
32
8 x 64
38
24 x 64
33
12 x 64
39
26 x 32
34
16 x 64
40
26 x 40
35
24 x 32
41
26 x 48
36
24 x 36
42
26 x 64
DMRE symbol sizes may be activated in automatic mode using the option --dmre or by the API option_3 = DM_DMRE');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (35, 58, 'BARCODE_QRCODE', 'QR Code (ISO 18004)', 2, 1, false, true, false, 'Also known as Quick Response Code this symbology was developed by Denso. Four levels of error correction are available using the --security= option or setting option_1 as shown in the following table.
Input
ECC Level
Error Correction Capacity
Recovery Capacity
1
L (default)
Approx 20% of symbol
Approx 7%
2
M
Approx 37% of symbol
Approx 15%
3
Q
Approx 55% of symbol
Approx 25%
4
H
Approx 65% of symbol
Approx 30%
The size of the symbol can be set by using the --vers= option or by setting option_2 to the QR Code version required (1-40). The size of symbol generated is shown in the table below.
Input
symbol Size
Input
symbol Size
1
21 x 21
21
101 x 101
2
25 x 25
22
105 x 105
3
29 x 29
23
109 x 109
4
33 x 33
24
113 x 113
5
37 x 37
25
117 x 117
6
41 x 41
26
121 x 121
7
45 x 45
27
125 x 125
8
49 x 49
28
129 x 129
9
53 x 53
29
133 x 133
10
57 x 57
30
137 x 137
11
61 x 61
31
141 x 141
12
65 x 65
32
145 x 145
13
69 x 69
33
149 x 149
14
73 x 73
34
153 x 153
15
77 x 77
35
157 x 157
16
81 x 81
36
161 x 161
17
85 x 85
37
165 x 165
18
89 x 89
38
169 x 169
19
93 x 93
39
173 x 173
20
97 x 97
40
177 x 177
The maximum capacity of a (version 40) QR Code symbol is 7089 numeric digits, 4296 alphanumeric characters or 2953 bytes of data. QR Code symbols can also be used to encode GS1 data. QR Code symbols can by default encode characters in the Latin-1 set and Kanji characters which are members of the Shift-JIS encoding scheme. In addition QR Code supports using other character sets using the ECI mechanism. Input should usually be entered as Unicode (UTF-8) with conversion to Shift-JIS being carried out by Zint. A separate symbology ID can be used to encode Health Industry Barcode (HIBC) data which adds a leading ''+'' character and a modulo-49 check digit to the encoded data.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (34, 57, 'BARCODE_MAXICODE', 'Maxicode (ISO 16023)', 2, 1, true, true, false, 'Developed by UPS the Maxicode symbology employs a grid of hexagons surrounding a ''bulls-eye'' finder pattern. This symbology is designed for the identification of parcels. Maxicode symbols can be encoded in one of five modes. In modes 2 and 3 Maxicode symbols are composed of two parts named the primary and secondary messages. The primary message consists of a structured data field which includes various data aboxut the package being sent and the secondary message usually consists of address data in a data structure. The format of the primary message required by Zint is given in the following table:
Characters
Meaning
1-9
Postcode data which can consist of up to 9 digits (for mode 2) or up to 6 alphanumeric characters (for mode 3). Remaining unused characters should be filled with the SPACE character (ASCII 32).
10-12
Three digit country code according to ISO 3166 (see Appendix B).
13-15
Three digit service code. This depends on your parcel courier.
The primary message can be set at the command prompt using the
--primary=
switch. The secondary message uses the normal data entry method. For example:
zint -o test.eps -b 57 --primary=''999999999840012'' -d ''Secondary Message Here''
When using the API the primary message must be placed in the symbol->primary string. The secondary is entered in the same way as described in section 5.2. When either of these modes is selected Zint will analyse the primary message and select either mode 2 or mode 3 as appropriate.
Modes 4 to 6 can be accessed using the --mode= switch or by setting option_1. Modes 4 to 6 do not require a primary message. For example:
zint -o test.eps -b 57 --mode=4 -d ''A MaxiCode Message in Mode 4''
Mode 6 is reserved for the maintenance of scanner hardware and should not be used to encode user data.
This symbology uses Latin-1 character encoding by default but also supports the ECI encoding mechanism. The maximum length of text which can be placed in a Maxicode symbol depends on the type of characters used in the text.
Example maximum data lengths are given in the table below:
Mode
Maximum Data Length for Capital Letters
Maximum Data Length for Numeric Digits
Number of Error Correction Codewords
2 (secondary only)
84
126
50
3 (secondary only)
84
126
50
4
93
135
50
5
77
110
66
6
93
135
50');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (23, 34, 'BARCODE_UPCA', 'UPC Version A', 1, 11, true, false, true, 'UPC-A is used in the United States for retail applications. The symbol requires an 11 digit article number. The check digit is calculated by Zint. In addition EAN-2 and EAN-5 add-on symbols can be added using the + character. For example, to draw a UPC-A symbol with the data 72527270270 with an EAN-5 add-on showing the data 12345 use the command:
zint --barcode=34 -d 72527270270+12345
or encode a data string with the + character included:
my_symbol->symbology = BARCODE_UPCA;
error = ZBarcode_Encode_and_Print(my_symbol, "72527270270+12345");
If your input data already includes the check digit symbology 35 can be used which takes a 12 digit input and validates the check digit before encoding.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (24, 37, 'BARCODE_UPCE', 'UPC Version E', 1, 6, true, false, true, 'UPC-E is a zero-compressed version of UPC-A developed for smaller packages. The code requires a 6 digit article number (digits 0-9). The check digit is calculated by Zint. EAN-2 and EAN-5 add-on symbols can be added using the + character as with UPC-A. In addition Zint also supports Number System 1 encoding by entering a 7-digit article number stating with the digit 1. For example:
zint --barcode=37 -d 1123456
or
my_symbol->symbology = BARCODE_UPCE;
error = ZBarcode_Encode_and_Print(my_symbol, "1123456");
If your input data already includes the check digit symbology 38 can be used which takes a 7 or 8 digit input and validates the check digit before encoding.');
INSERT INTO bc_symbols (bc_symbol_id, bc_symbol_zint_id, bc_symbol_zint_constant, bc_symbol_name, bc_symbol_dim, bc_symbol_minlength, bc_symbol_numeric, bc_symbol_parity, bc_symbol_checkdigit, bc_symbol_notes) VALUES (59, 92, 'BARCODE_AZTEC', 'Aztec Code (ISO 24778)', 2, 1, false, true, true, 'Invented by Andrew Longacre at Welch Allyn Inc in 1995 the Aztec Code symbol is a matrix symbol with a distinctive bulls-eye finder pattern. Zint can generate Compact Aztec Code (sometimes called Small Aztec Code) as well as "full-range" Aztec Code symbols and by default will automatically select symbol type and size dependent on the length of the data to be encoded. Error correction codewords will normally be generated to fill at least 23% of the symbol. Two options are available to change this behaviour:
The size of the symbol can be specified using the --ver= option or setting option_2 to a value between 1 and 36 according to the following table. The symbols marked with an asterisk (*) in the table below are "compact" symbols, meaning they have a smaller bulls-eye pattern at the centre of the symbol.
Input
symbol Size
Input
symbol Size
1
15 x 15*
19
79 x 79
2
19 x 19*
20
83 x 83
3
23 x 23*
21
87 x 87
4
27 x 27*
22
91 x 91
5
19 x 19
23
95 x 95
6
23 x 23
24
101 x 101
7
27 x 27
25
105 x 105
8
31 x 31
26
109 x 109
9
37 x 37
27
113 x 113
10
41 x 41
28
117 x 117
11
45 x 45
29
121 x 121
12
49 x 49
30
125 x 125
13
53 x 53
31
131 x 131
14
57 x 57
32
135 x 135
15
61 x 61
33
139 x 139
16
67 x 67
34
143 x 143
17
71 x 71
35
147 x 147
18
75 x 75
36
151 x 151
Note that in symbols which have a specified size the amount of error correction is dependent on the length of the data input and Zint will allow error correction capacities as low as 3 codewords.
Alternatively the amount of error correction data can be specified by use of the --mode= option or by setting option_1 to a value from the following table:
Mode
Error Correction Capacity
1
>10% + 3 codewords
2
>23% + 3 codewords
3
>36% + 3 codewords
4
>50% + 3 codewords
It is not possible to select boxth symbol size and error correction capacity for the same symbol. If boxth options are selected then the error correction capacity selection will be ignored.
Aztec Code supports ECI encoding and can encode up to a maximum length of approximately 3823 numeric or 3067 alphabetic characters or 1914 bytes of data. A separate symbology ID can be used to encode Health Industry Barcode (HIBC) data which adds a leading ''+'' character and a modulo-49 check digit to the encoded data.');
