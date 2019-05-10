MODULE_big   = pgzint-0.1.4
OBJS         = pgzint.o
SHLIB_LINK   = -lzint -lpng
EXTENSION    = pgzint
DATA         = $(wildcard pgzint--*.sql)
DOCS         = README.md
TESTS        = $(wildcard test/sql/*.sql)
REGRESS      = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --inputdir=test --load-language=plpgsql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
