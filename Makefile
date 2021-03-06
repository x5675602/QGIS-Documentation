# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
LANG            = en
# currently we are building for the following languages, if you want yours to be build: ask!
LANGUAGES       = en # bg cs de es fi fr id it ja ko nl pt_BR pt_PT ro ru tr zh_Hant zh_Hans
SPHINXOPTS      =
SPHINXINTLOPTS  = $(SPHINXOPTS) -D language=$(LANG)
SPHINXBUILD     ?= sphinx-build
SPHINXINTL      ?= sphinx-intl
SOURCEDIR       = .
BUILDDIR        = build
#SITEDIR         = /var/www/html/qgisdocs
SITEDIR         = qgis2:/var/www/qgisdata/QGIS-Documentation/live/html
VERSION         = testing


# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

springclean:
	rm -r $(BUILDDIR)
	# all .mo files
	find $(SOURCEDIR)/locale/*/LC_MESSAGES/ -type f -name '*.mo' -delete

gettext:
	@$(SPHINXBUILD) -M gettext "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# this will build html-version of one language (defaults to english: en)
# to build for example dutch on Linux:
#  make LANG=nl html
# on windows:
#  set SPHINXOPTS=-D language=nl
#  make.bat html
# note that the translations/po files from git will be used
# so if you want most up to date files, download or use 'tx' to get those first

html:
	echo "$(SPHINXOPTS) $(SPHINXINTLOPTS)"
	if [ $(LANG) != "en" ]; then \
		$(SPHINXBUILD) -b html "$(SOURCEDIR)" "$(BUILDDIR)/html/$(LANG)" $(SPHINXINTLOPTS) $(0); \
	else \
		$(SPHINXBUILD) -b html -nW --keep-going "$(SOURCEDIR)" "$(BUILDDIR)/html/$(LANG)" $(SPHINXOPTS) $(0); \
	fi

latex:
	# for LANG=ja overwrites the default latex_engine=xelatex by latex_engine=platex
	$(eval SPHINXINTLOPTS += $(if $(filter $(LANG),ja),-D latex_engine=platex,))
	# A tag -t $LANG is used in the building process to allow for dynamic
	# settings in the conf.py. For example, for korean we need to use other
	# latex_elements and we use a if tags.has('ko') expression to overwrite the defaults
	$(SPHINXBUILD) -b latex -t $(LANG) "$(SOURCEDIR)" "$(BUILDDIR)/latex/$(LANG)" $(SPHINXINTLOPTS) $(0)


pdf: latex
	# Choose the correct latex compiler, equivalent to:
	# IF LANG=ja THEN LATEXCOMPILER = platex -kanji=euc ELSE LATEXCOMPILER = xelatex
	$(eval LATEXCOMPILER := $(if $(filter $(LANG),ja),platex,xelatex))

	# Compile the tex files into PDF, it runs 2x to fix hyperlinks
	# notice that platex compiler needs an extra step to convert dvi to PDF
	# using the dvipdfmx command
	cd $(BUILDDIR)/latex/$(LANG); \
	$(LATEXCOMPILER) -shell-escape QGISUserGuide.tex; \
	$(LATEXCOMPILER) -shell-escape QGISUserGuide.tex; \
	if [ "$(LATEXCOMPILER)" != "xelatex" ]; then dvipdfmx QGISUserGuide.dvi; fi; \
	$(LATEXCOMPILER) -shell-escape PyQGISDeveloperCookbook.tex; \
	$(LATEXCOMPILER) -shell-escape PyQGISDeveloperCookbook.tex; \
	if [ "$(LATEXCOMPILER)" != "xelatex" ]; then dvipdfmx PyQGISDeveloperCookbook.dvi; fi; \
	$(LATEXCOMPILER) -shell-escape QGISTrainingManual.tex; \
	$(LATEXCOMPILER) -shell-escape QGISTrainingManual.tex; \
	if [ "$(LATEXCOMPILER)" != "xelatex" ]; then dvipdfmx QGISTrainingManual.dvi; fi; \
	$(LATEXCOMPILER) -shell-escape QGISDocumentationGuidelines.tex; \
	$(LATEXCOMPILER) -shell-escape QGISDocumentationGuidelines.tex; \
	if [ "$(LATEXCOMPILER)" != "xelatex" ]; then dvipdfmx QGISDocumentationGuidelines.dvi; fi;

	# copy and rename PDF files to the pdf folder
	mkdir -p $(BUILDDIR)/pdf/$(LANG);
	mv $(BUILDDIR)/latex/$(LANG)/QGISUserGuide.pdf $(BUILDDIR)/pdf/$(LANG)/QGIS-$(VERSION)-UserGuide-$(LANG).pdf;
	mv $(BUILDDIR)/latex/$(LANG)/PyQGISDeveloperCookbook.pdf $(BUILDDIR)/pdf/$(LANG)/QGIS-$(VERSION)-PyQGISDeveloperCookbook-$(LANG).pdf;
	mv $(BUILDDIR)/latex/$(LANG)/QGISTrainingManual.pdf $(BUILDDIR)/pdf/$(LANG)/QGIS-$(VERSION)-TrainingManual-$(LANG).pdf;
	mv $(BUILDDIR)/latex/$(LANG)/QGISDocumentationGuidelines.pdf $(BUILDDIR)/pdf/$(LANG)/QGIS-$(VERSION)-DocumentationGuidelines-$(LANG).pdf;

zip:
	mkdir -p $(BUILDDIR)/zip;
	(cd $(BUILDDIR)/html; \
	zip -r QGIS-$(VERSION)-Documentation-$(LANG).zip $(LANG)/;)
	mv $(BUILDDIR)/html/QGIS-$(VERSION)-Documentation-$(LANG).zip $(BUILDDIR)/zip/;

site: html pdf zip
	rsync -az $(BUILDDIR)/html/$(LANG) $(SITEDIR)/;

# this will build ALL languages, AND tries to rsync them to the web dir on qgis2
# to be able to run this you will need a key on the server
all:
	@for LANG in $(LANGUAGES) ; do \
		make LANG=$$LANG site; \
	done
	rsync -az $(BUILDDIR)/pdf $(SITEDIR)/;
	rsync -az $(BUILDDIR)/zip $(SITEDIR)/;

# this will pull ALL translations (or at least from the languages we build for)
# to your local disk, so it can be committed into github
# in that way a build from git will contain those translation
# tx is the python transifex cli client (pip install transifex-client)
# because differences between chinese language codes in Sphinx and
# transifex, we need to replace the underscores by dashes,
# the english language is removed to avoid pulling the po source files.
# finally, the spaces are replaced by commas. In the end we have something like this
# tx pull -f --parallel -l lang1,lang2,lang2,lang4
tx_force_pull_translations:
	$(eval space := )
	$(eval space += )
	$(eval comma += ,)
	tx pull -f --parallel -l $(subst $(space),$(comma),$(subst en$(space),,$(subst zh_,zh-,$(LANGUAGES)))) ;

doctest:
	$(SPHINXBUILD) -b doctest . $(BUILDDIR)/doctest
	@echo "Testing of doctests in the sources finished, look at the " \
	      "results in $(BUILDDIR)/doctest/output.txt."
