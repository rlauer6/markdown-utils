VERSION = 1.02
RELEASE = 2

RPM_NAME = perl-Markdown-Render

RPM = $(RPM_NAME)-$(VERSION)-$(RELEASE).noarch.rpm
SPEC_FILE = $(RPM_NAME).spec

FILES = \
    README.md.in

MARKDOWN=$(FILES:.md.in=.md)
HTML=$(MARKDOWN:.md=.html)

$(MARKDOWN): % : %.in md-utils
	set -x; \
	./md-utils $< > $@ || (rm -f $@ && false);

$(HTML): $(MARKDOWN)
	./md-utils.pl -r $< > $@ || (rm -f $@ && false);

all: md-utils $(MARKDOWN) $(HTML)

markdown: $(MARKDOWN)

html: $(HTML)

md-utils: md-utils.pl
	cp $< $@
	chmod +x $@

$(RPM): $(SPEC_FILE)
	mkdir -p rpm/{RPMS,SOURCES,BUILDROOT,BUILD,SPEC}
	rpmbuild -ba $< \
	  --define "_sourcedir $$PWD/Markdown" \
	  --define "_topdir $$PWD/rpm" \
	  --define "_version $(VERSION)" \
	  --define "_prefix /usr/local" \
	  --define "_release $(RELEASE)"
	cp rpm/RPMS/noarch/$(RPM) $@

rpm: $(RPM)

.PHONY: rpm

clean:
	rm -f $(MARKDOWN)
	rm -rf rpm
	rm -f *.rpm

