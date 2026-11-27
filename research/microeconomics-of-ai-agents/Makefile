export SOURCE_DATE_EPOCH := 1795737600
export FORCE_SOURCE_DATE := 1

.PHONY: all clean
all: paper.pdf

paper.pdf: paper.tex references.tex
	latexmk -g -pdf -interaction=nonstopmode -halt-on-error paper.tex

clean:
	latexmk -c paper.tex
