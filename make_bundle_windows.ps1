param(
    [string]$OutFile = "bundle.txt",
    [int64]$MaxSizeBytes = 512KB
)

$root = Get-Location

$excludeDirs = @(
    ".git", ".hg", ".svn", ".idea", ".vscode", ".venv", "venv", "env",
    "node_modules", "dist", "build", "out", "target", ".gradle", ".next",
    ".nuxt", ".turbo", ".terraform", ".pytest_cache", ".mypy_cache",
    "coverage", ".tox"
)

$includeExt = @(
    ".py",".pyi",".java",".kt",".kts",".scala",".go",".rs",".c",".h",".hpp",
    ".hh",".hxx",".cc",".cpp",".cxx",".m",".mm",".cs",".php",".rb",".swift",
    ".dart",".ts",".tsx",".js",".jsx",".vue",".sql",".r",".jl",".hs",".erl",
    ".ex",".exs",".clj",".cljs",".scm",".lisp",".lua",
    ".yml",".yaml",".json",".toml",".ini",".cfg",".conf",
    ".props",".properties",
    ".md",".rst",".adoc",".org",".txt"
)

$includeNames = @(
    "Dockerfile","docker-compose.yml","docker-compose.yaml",
    "compose.yml","compose.yaml",
    "Makefile","CMakeLists.txt","pom.xml","build.gradle","build.gradle.kts",
    "settings.gradle","settings.gradle.kts","gradle.properties",
    "package.json","tsconfig.json",
    "webpack.config.js","webpack.config.cjs","webpack.config.mjs",
    "vite.config.js","vite.config.ts",
    "rollup.config.js","rollup.config.mjs",
    "requirements.txt","constraints.txt","pyproject.toml",
    "Pipfile","Pipfile.lock","poetry.lock",
    ".gitignore",".gitattributes",".editorconfig",
    ".prettierrc",".eslintrc",".flake8",".pylintrc",".yamllint",
    ".dockerignore",".gitlab-ci.yml"
)

# Очищаем / создаём файл в UTF-8
[System.IO.File]::WriteAllText($OutFile, "", [System.Text.Encoding]::UTF8)

Add-Content -Path $OutFile -Value "# Code bundle for ChatGPT" -Encoding UTF8
Add-Content -Path $OutFile -Value ("# Generated: {0}" -f (Get-Date -Format o)) -Encoding UTF8
Add-Content -Path $OutFile -Value ("# Root: {0}" -f $root) -Encoding UTF8
Add-Content -Path $OutFile -Value "" -Encoding UTF8

$sep = [IO.Path]::DirectorySeparatorChar

function IsExcludedPath([string]$path) {
    foreach ($dir in $excludeDirs) {
        if ($path -like "*$sep$dir$sep*" -or
            $path -like "*$sep$dir") {
            return $true
        }
    }
    return $false
}

Get-ChildItem -Recurse -File -Force |
    Where-Object {
        $_.Name -ne $OutFile -and
        $_.Length -le $MaxSizeBytes -and
        -not (IsExcludedPath $_.FullName) -and
        (
            $includeExt -contains $_.Extension.ToLowerInvariant() -or
            $includeNames -contains $_.Name
        )
    } |
    Sort-Object FullName |
    ForEach-Object {
        $rel = Resolve-Path -Relative $_.FullName
        Add-Content -Path $OutFile -Value ("===== FILE: {0} =====" -f $rel) -Encoding UTF8
        Get-Content -Path $_.FullName -Raw | Add-Content -Path $OutFile -Encoding UTF8
        Add-Content -Path $OutFile -Value ("`n===== END FILE: {0} =====`n" -f $rel) -Encoding UTF8
    }
