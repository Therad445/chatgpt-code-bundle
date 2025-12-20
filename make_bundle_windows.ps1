param(
    [string]$OutFile = "bundle.txt",
    [int64]$MaxSizeBytes = 512KB,
    [int]$FallbackCodePage = 1251   # если файл без BOM и не UTF-8, читаем как Windows-1251
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

$sep = [IO.Path]::DirectorySeparatorChar

function IsExcludedPath([string]$path) {
    foreach ($dir in $excludeDirs) {
        if ($path -like "*$sep$dir$sep*" -or $path -like "*$sep$dir") {
            return $true
        }
    }
    return $false
}

function Get-TextSmart([string]$path, [int]$fallbackCp) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    if ($bytes.Length -eq 0) { return "" }

    # если это случайно бинарник (нулевые байты) — лучше не портить бандл
    $nul = 0
    foreach ($b in $bytes) {
        if ($b -eq 0) { $nul++; if ($nul -ge 2) { return $null } }
    }

    # BOM detection
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2) # UTF-16 LE
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2) # UTF-16 BE
    }

    # No BOM: try strict UTF-8 first
    $utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        return $utf8Strict.GetString($bytes)
    } catch {
        # fallback (обычно cp1251)
        $fallback = [System.Text.Encoding]::GetEncoding($fallbackCp)
        return $fallback.GetString($bytes)
    }
}

# Пишем итоговый файл в UTF-8 с BOM (надёжнее для Windows-редакторов)
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$sw = New-Object System.IO.StreamWriter($OutFile, $false, $utf8Bom)

try {
    $sw.WriteLine("# Code bundle for ChatGPT")
    $sw.WriteLine(("# Generated: {0}" -f (Get-Date -Format o)))
    $sw.WriteLine(("# Root: {0}" -f $root))
    $sw.WriteLine()

    Get-ChildItem -Recurse -File -Force |
        Where-Object {
            $_.FullName -ne (Resolve-Path $OutFile -ErrorAction SilentlyContinue) -and
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

            $text = $null
            try {
                $text = Get-TextSmart -path $_.FullName -fallbackCp $FallbackCodePage
            } catch {
                $text = $null
            }

            if ($null -eq $text) {
                # пропускаем бинарь/битый файл, но оставим отметку
                $sw.WriteLine(("===== FILE: {0} =====" -f $rel))
                $sw.WriteLine("[SKIPPED: looks like binary or unreadable]")
                $sw.WriteLine(("`n===== END FILE: {0} =====`n" -f $rel))
                return
            }

            $sw.WriteLine(("===== FILE: {0} =====" -f $rel))
            $sw.Write($text)
            if (-not $text.EndsWith("`n")) { $sw.WriteLine() }
            $sw.WriteLine(("===== END FILE: {0} =====" -f $rel))
            $sw.WriteLine()
        }
}
finally {
    $sw.Dispose()
}
