MODULE = Markdown::Render	

AUTHOR = 'BIGFOOT <bigfoot@cpan.org>'

PERL_MODULES = \
    lib/Markdown/Render.pm

PERL_SCRIPTS = \
    bin/md-utils.pl

TARBALL = \
    Markdown-Render.tar.gz

all: $(TARBALL)

EXTRA: ChangeLog README.md t/00-markdown.t t/files/README.md.in

ChangeLog:
	cp ../ChangeLog $@

bin/md-utils.pl: ../md-utils.pl
	test -d bin/ || mkdir bin/
	cp ../md-utils.pl $@

lib/Markdown/Render.pm: ../Markdown/Render.pm
	test -d lib/Markdown || mkdir -p lib/Markdown
	cp ../Markdown/Render.pm $@ 

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

$(TARBALL): $(PERL_MODULES) $(PERL_SCRIPTS) $(EXTRA) extra
	 make-cpan-dist \
	   -e bin \
	   -f extra \
	   -l lib \
	   -M 5.016 \
	   -m $(MODULE) \
	   -a $(AUTHOR) \
	   -d $(DESCRIPTION) \
	   -H .
	cp $$(ls -1rt *.tar.gz | tail -1) $@

README.md: ../README.md.in
	../md-utils.pl  $< > $@ || rm -f $@

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
