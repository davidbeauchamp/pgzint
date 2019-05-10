DROP FUNCTION bc_generate(
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
  protation integer
);
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
AS '$libdir/pgzint'
LANGUAGE C IMMUTABLE;
