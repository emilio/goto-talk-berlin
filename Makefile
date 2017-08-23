.PHONY: slides
slides: index.md
	pandoc --self-contained -s -t revealjs $< -o $@
