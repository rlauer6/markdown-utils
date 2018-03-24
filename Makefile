FILES = \
    README.md.in

MARKDOWN=$(FILES:.md.in=.md)
HTML=$(MARKDOWN:.md=.html)

$(MARKDOWN): % : %.in
	md-utils $< > $@

$(HTML): $(MARKDOWN)
	md-utils -r $< > $@

all: $(MARKDOWN) $(HTML)

markdown: $(MARKDOWN)

html: $(HTML)

clean:
	rm -f $(MARKDOWN) $(HTML)
