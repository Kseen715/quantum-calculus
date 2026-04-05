# Quantum Calculus

## Building PDFs from Jupyter notebooks

This repository builds Jupyter notebooks into PDFs and generates artifacts in the `output/` folder.

### Prerequisites

The Makefile checks for the following tools before building:

- `jupyter` (used to run `nbconvert`)
- `sha256sum`
- `python3`
- `gpg` only when signing is requested

If a required tool is missing, the build stops and prints a short install hint.

### Build targets

- `make check-tools`
  - Verifies required tools are installed before the build

- `make all`
  - Converts all `*.ipynb` notebooks into PDFs
  - Writes SHA256 checksum files next to each generated PDF
  - Generates `output/manifest.json`
  - If `GPG_KEY` is set, signs PDFs after the build

- `make checksums`
  - Creates SHA256 checksum files for each PDF in `output/`
  - Verifies the generated checksums immediately

- `make sign GPG_KEY=<key-id>`
  - Creates detached GPG signatures for every PDF in `output/`
  - Verifies each signature after signing
  - Optionally set `GPG_PASSPHRASE` if the key is passphrase-protected

- `make clean`
  - Removes generated files from `output/`

- `make help`
  - Prints a shorter usage summary

### Examples

Build PDFs and checksums only:

```bash
make -j4 all
```

Build and sign PDFs with a GPG key:

```bash
GPG_KEY=... make -j4 all
```

Sign existing PDFs in `output/`:

```bash
make sign GPG_KEY=...
```

If your key requires a passphrase:

```bash
GPG_KEY=... GPG_PASSPHRASE="your-passphrase" make sign
```

### Output artifacts

The build generates the following files in `output/`:

- `*.pdf`
- `*.pdf.sha256`
- `*.pdf.sig` (when signing)
- `manifest.json`

### Notes

- The Makefile detects all notebooks in the repository automatically.
- The PDF build runs via `jupyter nbconvert` from `.venv/bin/jupyter` when available.
- All outputs are written into `output/` to keep the repository root clean.
