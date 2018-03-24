# Table of Contents

* [README](#readme)
* [Installation](#installation)
* [Usage](#usage)
  * [Rendering](#rendering)
* [Credits](#credits)


# README

A quick search regarding how to get a table of contents into my
markdown yieled only few hits or projects that seemed a little weighty
to me, shere's a quick 'n dirty Perl script with few dependencies that you
might find useful.  See [Usage](#usage) for more information.

# Installation


```
git clone https://github.com/rlauer6/markdown-utils.git
sudo ln -s $(pwd)/markdown-utils/md-utlils.pl /usr/bin/md-utils
```

# Usage

1. Add # Table of Contents

* [README](#readme)
* [Installation](#installation)
* [Usage](#usage)
  * [Rendering](#rendering)
* [Credits](#credits)
 somewhere in your markdown
1. Insert the table of contents to you markdown
  ```
  cat README.md.in | md-utils.pl > README.md
  ```

...or...kick it old school with a `Makefile`

```
FILES = \
    README.md.in

MARKDOWN=$(FILES:.md.in=.md)
HTML=$(MARKDOWN:.md=.html)

$(MARKDOWN): % : %.in
	md-utils.pl $< > $@

$(HTML): $(MARKDOWN)
	md-utils.pl -r $< > $@

all: $(MARKDOWN) $(HTML)

markdown: $(MARKDOWN)

html: $(HTML)

clean:
	rm -f $(MARKDOWN) $(HTML)
```

## Rendering

Using the GiHub rendering API, you can create HTML pretty easily.

```
jq --slurp --raw-input '{"text": "\(.)", "mode": "markdown"}' < README.md | \
  curl -s --data @- https://api.github.com/markdown
```

__...but alas you might find that your internal links don't work...__

Never fear...the `--render` option of this utility will set that right for
you and create final HTML file where internal links really work.

```
md-utils.pl --render README.md > README.html
```
# Credits

Rob Lauer - <rlauer6@comcast.net>
