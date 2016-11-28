MODULE_big = pgzint
OBJS = pgzint.o
SHLIB_LINK = -lzint -lpng
EXTENSION = pgzint
DATA = pgzint--0.1.0.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
