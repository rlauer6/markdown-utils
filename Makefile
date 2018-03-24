FILES = \
    README.md.in

MARKDOWN=$(FILES:.md.in=.md)
HTML=$(MARKDOWN:.md=.html)

$(MARKDOWN): % : %.in
	md-utils $< > $@ || (rm -f $@ && false);

$(HTML): $(MARKDOWN)
	md-utils -r $< > $@ || (rm -f $@ && false);

all: $(MARKDOWN) $(HTML)

markdown: $(MARKDOWN)

html: $(HTML)

clean:
	rm -f $(MARKDOWN) $(HTML)
