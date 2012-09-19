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

all: deps compile

deps: generate_config
	./rebar get-deps

compile: generate_config
	./rebar compile

generate_config:
	if [ ! -f enabled_plugins ]; then \
		echo "[]." > enabled_plugins; \
	fi
	cat oacd_core/rebar.config.template | sed -e "s:@OACD_DEPS_DIR@:../deps:g" > oacd_core/rebar.config
	for plugin in oacd_plugins/*; do \
		if [ -f $$plugin/rebar.config.template ]; then \
			cat $$plugin/rebar.config.template | sed -e "s:@OACD_DEPS_DIR@:../../deps:g" > $$plugin/rebar.config; \
		fi \
	done

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
	for app in ./oacd_plugins/*; do \
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