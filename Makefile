BINDIR=test/bin
ETCDIR=test/etc
LIBDIR=test/lib
VARDIR=test/var

OADIR=$(LIBDIR)/openacd
OALIBDIR=$(OADIR)/lib
OABINDIR=$(OADIR)/bin
OACONFIGDIR=$(ETCDIR)/openacd
OAVARDIR=$(VARDIR)/lib/openacd
OALOGDIR=$(VARDIR)/log/openacd
OADBDIR=$(OAVARDIR)/db
OAPLUGINDIR=$(OADIR)/plugin.d

all: checkout deps compile

deps:
	./rebar get-deps

compile:
	./rebar compile

checkout: core/oacd_core/src

core/oacd_core/src:
	git submodule init
	git submodule update

install:
	mkdir -p $(DESTDIR)$(PREFIX)$(BINDIR)
	mkdir -p $(DESTDIR)$(PREFIX)$(OADIR)
	mkdir -p $(DESTDIR)$(PREFIX)$(OALIBDIR)
	mkdir -p $(DESTDIR)$(PREFIX)$(OABINDIR)
	mkdir -p $(DESTDIR)$(PREFIX)$(OACONFIGDIR)
	mkdir -p $(DESTDIR)$(PREFIX)$(OAVARDIR)
	mkdir -p $(DESTDIR)$(PREFIX)$(OAPLUGINDIR)
	for dep in deps/*; do \
	  ./install.sh $$dep $(DESTDIR)$(PREFIX)$(OALIBDIR) ; \
	done
	./install.sh . $(DESTDIR)$(PREFIX)$(OALIBDIR)
	for app in ./plugins/*; do \
	  ./install.sh $$app $(DESTDIR)$(PREFIX)$(OALIBDIR) ; \
	done
## Plug-ins
	mkdir -p $(DESTDIR)$(PREFIX)$(OAPLUGINDIR)
## Configurations
	sed \
	-e 's|%LOG_DIR%|$(OALOGDIR)|g' \
	-e 's|%PLUGIN_DIR%|$(PREFIX)$(OAPLUGINDIR)|g' \
	./config/app.config > $(DESTDIR)$(PREFIX)$(OACONFIGDIR)/app.config
	sed \
	-e 's|%DB_DIR%|$(PREFIX)$(OADBDIR)|g' \
	./config/vm.args > $(DESTDIR)$(PREFIX)$(OACONFIGDIR)/vm.args
## Var dirs
	mkdir -p $(DESTDIR)$(PREFIX)$(OADBDIR)
	mkdir -p $(DESTDIR)$(PREFIX)$(OALOGDIR)
## Bin
#dont use DESTDIR in sed here;this is a hack to not get "rpmbuild found in installed files"
	sed \
	-e 's|%OPENACD_PREFIX%|"$(PREFIX)"|g' \
	-e 's|%LIB_DIR%|$(libdir)|g' \
	./scripts/openacd > $(DESTDIR)$(PREFIX)$(OABINDIR)/openacd
	chmod +x $(DESTDIR)$(PREFIX)$(OABINDIR)/openacd
	cp ./scripts/nodetool $(DESTDIR)$(PREFIX)$(OABINDIR)
	cd $(DESTDIR)$(PREFIX)$(BINDIR); \
	ln -sf $(PREFIX)$(OABINDIR)/openacd openacd; \
	ln -sf $(PREFIX)$(OABINDIR)/nodetool nodetool

.PHONY: all deps compile checkout install

