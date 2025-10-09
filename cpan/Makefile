MODULE = Markdown::Render	

SHELL := /bin/bash

.SHELLFLAGS := -ec

VERSION := $(shell cat ../VERSION)

AUTHOR = 'BIGFOOT <bigfoot@cpan.org>'

PERL_MODULES = \
    ../lib/Markdown/Render.pm

GPERL_MODULES = \
    lib/Markdown/Render.pm

PERL_SCRIPTS = \
    ../bin/md-utils.pl

GPERL_SCRIPTS = \
    bin/md-utils.pl

TARBALL = \
    Markdown-Render-$(VERSION).tar.gz

all: $(TARBALL)

EXTRA: ChangeLog README.md t/00-markdown.t t/files/README.md.in

ChangeLog: ../ChangeLog
	cp ../ChangeLog $@

$(GPERL_SCRIPTS): $(PERL_SCRIPTS)
	test -d bin/ || mkdir bin/
	cp $< $@
	chmod +x $@

$(GPERL_MODULES): $(PERL_MODULES)
	test -d lib/Markdown || mkdir -p lib/Markdown
	cp $< $@

DESCRIPTION = "Render markdown using GitHub API"

UNIT_TESTS = 

EXTRA = \
    ChangeLog \
    README.md \
    t/00-markdown.t \
    t/files/README.md.in

extra:
	rm -f $@
	for a in $(EXTRA); do \
	  echo $$a >> $@; \
	done

$(TARBALL): $(GPERL_MODULES) $(GPERL_SCRIPTS) $(EXTRA) extra
	 make-cpan-dist \
	   -e bin \
	   -f extra \
	   -l lib \
	   -M 5.016 \
	   -m $(MODULE) \
	   -a $(AUTHOR) \
	   -d $(DESCRIPTION) \
	   -H .

README.md: ../README.md.in
	../bin/md-utils.pl  $< > $@ || rm -f $@

t/files/README.md.in: ../README.md.in
	test -d t/files || mkdir -p t/files
	cp $< $@

t/00-markdown.t: ../t/00-markdown.t
	test -d t || mkdir -p t
	cp $< $@

install: $(TARBALL)
	cpanm -v -l $$HOME  $<

CLEANFILES =  \
    $(TARBALL) \
    README.md \
    ChangeLog \
    requires \
    provides \
    extra

PHONY: clean

clean:
	rm -f *.tar.gz
	for a in $(CLEANFILES); do \
	  rm -f $$a; \
	done
