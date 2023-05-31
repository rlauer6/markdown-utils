MODULE = Markdown::Render	

AUTHOR = 'BIGFOOT <bigfoot@cpan.org>'

PERL_MODULES = \
    lib/Markdown/Render.pm

PERL_SCRIPTS = \
    bin/md-utils.pl

TARBALL = \
    Markdown-Render.tar.gz

all: $(TARBALL)

EXTRA: ChangeLog README.md

ChangeLog:
	cp ../ChangeLog $@

bin/md-utils.pl:
	cp ../md-utils.pl $@

lib/Markdown/Render.pm:
	test -d lib/Markdown || mkdir -p lib/Markdown
	cp ../Markdown/Render.pm $@ 

DESCRIPTION = "Render markdown using GitHub API"

UNIT_TESTS = 

EXTRA = \
    ChangeLog \
    README.md

extra:
	rm -f $@
	for a in $(EXTRA); do \
	  echo $$a >> $@; \
	done

$(TARBALL): $(PERL_MODULES) $(PERL_SCRIPTS) ChangeLog README.md extra
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
