# chatgpt-code-bundle

Small cross-platform helper to generate a **single text bundle** of your codebase
that is convenient to paste into ChatGPT.

It:

- Skips heavy and noisy directories (`.git`, `node_modules`, `dist`, `build`, virtualenvs, caches, etc.).
- Includes source code, configs, infrastructure and docs.
- Limits individual file size (≤ 512 KiB) to avoid huge blobs.
- Produces a readable format:

# Usage on Linux / macOS

Copy the script into your project root:

cp /path/to/chatgpt-code-bundle/make_bundle_unix.sh ./make_bundle.sh
chmod +x make_bundle.sh

# Usage on Windows (PowerShell)

Copy the script into your project root as make_bundle_windows.ps1.

In PowerShell:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.\make_bundle_windows.ps1              # creates bundle.txt
.\make_bundle_windows.ps1 -OutFile hw7.txt

Run:

./make_bundle.sh           # creates bundle.txt
./make_bundle.sh hw7.txt   # custom output file name


Then open bundle.txt, copy the needed chunks and paste them into ChatGPT.

```text
===== FILE: path/to/file.ext =====
...file content...
===== END FILE: path/to/file.ext =====