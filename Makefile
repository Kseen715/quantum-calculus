
SHELL := /usr/bin/env bash
VENVBIN := .venv/bin
JUPYTER := $(VENVBIN)/jupyter
OUTDIR := output
NB := $(wildcard *.ipynb)
PDFS := $(patsubst %.ipynb,$(OUTDIR)/%.pdf,$(NB))
SHA := $(patsubst %.pdf,%.pdf.sha256,$(PDFS))
SIG := $(patsubst %.pdf,%.pdf.sig,$(PDFS))
MANIFEST := $(OUTDIR)/manifest.json

.PHONY: all checksums sign clean help

all: $(OUTDIR) $(PDFS) checksums
	@if [ -z "$(strip $(GPG_KEY))" ]; then \
		echo "No GPG_KEY set; skipping signing."; \
	else \
		echo "Signing with GPG_KEY=$(GPG_KEY)..."; \
		$(MAKE) --no-print-directory -j1 sign GPG_KEY=$(GPG_KEY); \
	fi
	@python3 scripts/generate_manifest.py $(OUTDIR)

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OUTDIR)/%.pdf: %.ipynb | $(OUTDIR)
	@echo "Converting $< -> $@"
	$(JUPYTER) nbconvert --to pdf --config scripts/nbconvert_config.py --output-dir $(OUTDIR) "$<"

checksums: verify-checksums

$(OUTDIR)/%.pdf.sha256: $(OUTDIR)/%.pdf
	sha256sum "$<" > "$@"
	@echo "Wrote $@"

verify-checksums: $(SHA)
	@set -e; \
	for f in $(SHA); do \
		echo "Verifying $$f"; \
		sha256sum -c "$$f" || { echo "Checksum verification failed: $$f"; exit 1; }; \
	done; \
	echo "All checksums OK."

# Generate JSON manifest for PDFs in $(OUTDIR)
manifest: $(MANIFEST)

MANIFEST_DEPS := $(PDFS) $(SHA)
ifeq ($(strip $(GPG_KEY)),)
MANIFEST_DEPS +=
else
MANIFEST_DEPS += sign
endif

$(MANIFEST): $(MANIFEST_DEPS)
	@echo "Generating manifest $@"
	@python3 scripts/generate_manifest.py $(OUTDIR)

ifeq ($(strip $(GPG_KEY)),)
sign:
	@echo "GPG_KEY not set. Run: make sign GPG_KEY=YOUR_KEY"
else
sign: $(PDFS)
	@set -e; \
	for pdf in $(PDFS); do \
		sig=$$pdf.sig; \
		echo "Signing $$pdf -> $$sig"; \
		if [ -n "$(strip $(GPG_PASSPHRASE))" ]; then \
			printf '%s\n' "$(GPG_PASSPHRASE)" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --output "$$sig" --detach-sign --local-user "$(GPG_KEY)" --armor "$$pdf"; \
		else \
			gpg --yes --output "$$sig" --detach-sign --local-user "$(GPG_KEY)" --armor "$$pdf"; \
		fi; \
		echo "Verifying signature $$sig for $$pdf"; \
		gpg --verify "$$sig" "$$pdf"; \
	done
endif

clean:
	rm -rf $(OUTDIR)/*

help:
	@echo "Usage: make [all|checksums|sign|clean] [-jN]"
	@echo "  all      Build PDFs and checksums (outputs in $(OUTDIR)/)"
	@echo "           When GPG_KEY is set, also sign PDFs after build."
	@echo "  sign     Create GPG detached signatures (set GPG_KEY=your-key)"
	@echo "           Optionally set GPG_PASSPHRASE in the environment."
	@echo "  clean    Remove PDFs, checksums, signatures from $(OUTDIR)/"
