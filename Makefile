VERSION=$(shell date -I)
MESSAGE=Release $(VERSION)

YELLOW=\033[1m\033[93m
CYAN=\033[1m\033[96m
CLEAR=\033[0m

PDF=$(patsubst content/article/%.md,public/pdf/%.pdf,$(wildcard content/article/*.md))
EPUB=$(patsubst content/article/%.md,public/epub/%.epub,$(wildcard content/article/*.md))

all: clean generate sync

dirs:
	@echo "$(YELLOW)Creating directories$(CLEAR)"
	mkdir -p public/pdf public/epub

public/pdf/%.pdf: content/article/%.md
	md2pdf -i content/article -o $@ $<

public/epub/%.epub: content/article/%.md image_dir.py
	pandoc -t epub -o $@ --filter ./image_dir.py $<

generate: dirs $(PDF) $(EPUB)
	@echo "$(YELLOW)Generating static site$(CLEAR)"
	hugo

cv:
	@echo "$(YELLOW)Generating resume$(CLEAR)"
	cp content/article/michel-casabianca.md /tmp/
	cd /tmp && \
		md2pdf michel-casabianca.md && \
		pandoc -t docx -o michel-casabianca.docx michel-casabianca.md && \
		upload-public michel-casabianca.pdf michel-casabianca.docx && \
		rm michel-casabianca.md michel-casabianca.pdf michel-casabianca.docx

sync:
	@echo "$(YELLOW)Syncing website$(CLEAR)"
	rsync -av public/ casa@sweetohm.net:/home/web/sweetohm/

update:
	@echo "$(YELLOW)Update site if changed on remote master$(CLEAR)"
	git fetch
	if [ `git rev-parse origin/master` != `git rev-parse HEAD` ]; then \
		git pull && make generate sync; \
	fi

server: dirs $(PDF) $(EPUB)
	@echo "$(YELLOW)Running development server$(CLEAR)"
	hugo server --watch

release:
	@echo "$(YELLOW)Releasing project$(CLEAR)"
	git tag -a "$(VERSION)" -m "$(MESSAGE)"
	git push origin "$(VERSION)"

clean:
	@echo "$(YELLOW)Cleaning generated files$(CLEAR)"
	rm -rf public/

help:
	@echo "$(CYAN)dirs$(CLEAR)      Create destination directories"
	@echo "$(CYAN)generate$(CLEAR)  Generate static site"
	@echo "$(CYAN)sync$(CLEAR)      Synchronize site with server"
	@echo "$(CYAN)server$(CLEAR)    Run development server"
	@echo "$(CYAN)release$(CLEAR)   Release project"
	@echo "$(CYAN)clean$(CLEAR)     Clean generated files"

