.RECIPEPREFIX := >
export SOURCE_DATE_EPOCH := 1795564800
export FORCE_SOURCE_DATE := 1
.PHONY: all check clean
all: paper.pdf
paper.pdf: paper.tex
>latexmk -g -pdf -interaction=nonstopmode -halt-on-error paper.tex
check:
>python3 check_model.py
clean:
>latexmk -c paper.tex
