BOOK_NAME=temoignage
PDFX_NAME=$(BOOK_NAME)_pdfx_1a
LINENO_PATT=\\pagewiselinenumbers
TEXINPUTS=
FONTSDIR=fonts
TODAY=$(shell date --iso)
TARGETS=$(BOOK_NAME) $(BOOK_NAME)_numbered $(BOOK_NAME)_interior
LATEX_INTERACTION=batchmode
FTP_TOPDIR=calvary
FTP_PDFDIR=$(FTP_TOPDIR)/pdf
FTP_JSONDIR=$(FTP_TOPDIR)/json
FTP_EBOOKDIR=$(FTP_TOPDIR)/ebooks

# Ebook settings
KINDLE_PATH=/documents/raphael
AUTHOR=Charles-Édouard Babut
LANGUAGE=fr
PUBDATE=$(shell date +'%Y-%m-%d')
COVER=cover/temoignage.png
TITLE=Le témoignage que Jésus se rend à lui-même

EBOOK_CONVERT_OPTS=--authors "$(AUTHOR)" --title "$(TITLE)" --language "$(LANGUAGE)" --pubdate "$(PUBDATE)" --page-breaks-before "//*[name()='h1' or name()='h2']" --cover "$(COVER)" --use-auto-toc  --level1-toc "//*[name()='h2']" --level2-toc "//*[name()='h3']" --minimum-line-height=0.4 --font-size-mapping "10,12,14,16,18,20,26,64"

all: pdf

pdf: $(addsuffix .pdf,$(TARGETS))

ebooks: mobi epub

mobi: $(BOOK_NAME).mobi

epub: $(BOOK_NAME).epub

json: pdf $(addsuffix .json,$(TARGETS))

%_numbered.tex: %.tex
	sed -e 's@%$(LINENO_PATT)@$(LINENO_PATT)@' $< > $@

%.pdf: %.tex
	OSFONTDIR=$(FONTSDIR) TEXINPUTS=$(TEXINPUTS) lualatex -shell-escape -interaction=$(LATEX_INTERACTION) $*
	OSFONTDIR=$(FONTSDIR) TEXINPUTS=$(TEXINPUTS) lualatex -shell-escape -interaction=$(LATEX_INTERACTION) $*

%_split.html: %.tex
	OSFONTDIR=$(FONTSDIR) TEXINPUTS=$(TEXINPUTS) htlatex $< \
	   'ebook.cfg,xhtml,2,charset=utf-8' ' -cunihtf -utf8 -cvalidate'
	bash cleanuphtml.sh $*.html

%.html: %.tex
	OSFONTDIR=$(FONTSDIR) TEXINPUTS=$(TEXINPUTS) htlatex $< \
	   'ebook.cfg,xhtml,charset=utf-8' ' -cunihtf -utf8 -cvalidate'
	bash cleanuphtml.sh $@

%_embedded.epub: %.epub
	rm -rf $*
	unzip  -d $* $<
	cp -r fonts $*/
	# Add fons to stylesheet.css
	cat fonts.css >> $*/stylesheet.css
	# Insert fonts into content.opf
	sed -i '/<manifest>/ r fonts.content' $*/content.opf
	# Regenerate zip
	cd $* && zip -Xr9D $(CURDIR)/$@ mimetype *

%.epub: %.html
	ebook-convert $< $@ $(EBOOK_CONVERT_OPTS) --preserve-cover-aspect-ratio

%.mobi: %.epub
	#ebook-convert $< $@ $(EBOOK_CONVERT_OPTS) --mobi-file-type "both"
	kindlegen $<

%-to-kindle: %.mobi
	# cp -f doesn't work, we need to remove
	ebook-device rm "$(KINDLE_PATH)/$<"
	-ebook-device mkdir "$(KINDLE_PATH)"
	ebook-device cp $< "prs500:$(KINDLE_PATH)/$<"

crocupload: $(BOOK_NAME).json split $(BOOK_NAME)_split.json

clean:
	rm -f *.ps *.aux *.log *.out *.lol
	rm -f *.idx *.ind *.ilg *.toc *.dvi
	rm -f make-split-stamp split-stamp
	rm -rf splits split
	rm -f *.xmpi
	rm -f *.html *.4tc *.tmp *.xref *.4ct
	rm -f *.epub *.mobi
	rm -f *.idv *.lg
	rm -f *.json
	# Remove only target pdf
	rm -f $(addsuffix .pdf,$(TARGETS))

