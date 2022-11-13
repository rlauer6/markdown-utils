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

clean:
	rm -f $(MARKDOWN) $(HTML)
