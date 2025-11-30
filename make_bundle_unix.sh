#!/usr/bin/env bash
set -euo pipefail

# Имя выходного файла можно передать первым аргументом, по умолчанию bundle.txt
OUT="${1:-bundle.txt}"

# Максимальный размер файла (всё, что <= 512 КБ, попадёт в бандл)
MAX_SIZE="512k"

# Очищаем старый бандл
: > "$OUT"

{
  echo "# Code bundle for ChatGPT"
  echo "# Generated: $(date -Iseconds 2>/dev/null || date)"
  echo "# Root: $(pwd)"
  echo
} >> "$OUT"

find . \
  \( \
    -path "./.git"          -o \
    -path "./.hg"           -o \
    -path "./.svn"          -o \
    -path "./.idea"         -o \
    -path "./.vscode"       -o \
    -path "./.venv"         -o \
    -path "./venv"          -o \
    -path "./env"           -o \
    -path "*/__pycache__"   -o \
    -path "./node_modules"  -o \
    -path "./dist"          -o \
    -path "./build"         -o \
    -path "./out"           -o \
    -path "./target"        -o \
    -path "./.gradle"       -o \
    -path "./.next"         -o \
    -path "./.nuxt"         -o \
    -path "./.turbo"        -o \
    -path "./.terraform"    -o \
    -path "./.pytest_cache" -o \
    -path "./.mypy_cache"   -o \
    -path "./coverage"      -o \
    -path "./.tox" \
  \) -prune -o \
  -type f \
  ! -name "$OUT" \
  -size -"${MAX_SIZE}" \
  \( \
    ##### КОД
    -iname "*.py"      -o \
    -iname "*.pyi"     -o \
    -iname "*.java"    -o \
    -iname "*.kt"      -o \
    -iname "*.kts"     -o \
    -iname "*.scala"   -o \
    -iname "*.go"      -o \
    -iname "*.rs"      -o \
    -iname "*.c"       -o \
    -iname "*.h"       -o \
    -iname "*.hpp"     -o \
    -iname "*.hh"      -o \
    -iname "*.hxx"     -o \
    -iname "*.cc"      -o \
    -iname "*.cpp"     -o \
    -iname "*.cxx"     -o \
    -iname "*.m"       -o \
    -iname "*.mm"      -o \
    -iname "*.cs"      -o \
    -iname "*.php"     -o \
    -iname "*.rb"      -o \
    -iname "*.swift"   -o \
    -iname "*.dart"    -o \
    -iname "*.ts"      -o \
    -iname "*.tsx"     -o \
    -iname "*.js"      -o \
    -iname "*.jsx"     -o \
    -iname "*.vue"     -o \
    -iname "*.sql"     -o \
    -iname "*.r"       -o \
    -iname "*.jl"      -o \
    -iname "*.hs"      -o \
    -iname "*.erl"     -o \
    -iname "*.ex"      -o \
    -iname "*.exs"     -o \
    -iname "*.clj"     -o \
    -iname "*.cljs"    -o \
    -iname "*.scm"     -o \
    -iname "*.lisp"    -o \
    -iname "*.lua"     -o \
    \
    ##### КОНФИГИ / INFRA / CI
    -iname "*.yml"     -o \
    -iname "*.yaml"    -o \
    -iname "*.json"    -o \
    -iname "*.toml"    -o \
    -iname "*.ini"     -o \
    -iname "*.cfg"     -o \
    -iname "*.conf"    -o \
    -iname "*.props"   -o \
    -iname "*.properties" -o \
    -iname "dockerfile"           -o \
    -iname "docker-compose.yml"   -o \
    -iname "docker-compose.yaml"  -o \
    -iname "compose.yml"          -o \
    -iname "compose.yaml"         -o \
    -iname "Makefile"             -o \
    -iname "CMakeLists.txt"       -o \
    -iname "pom.xml"              -o \
    -iname "build.gradle"         -o \
    -iname "build.gradle.kts"     -o \
    -iname "settings.gradle"      -o \
    -iname "settings.gradle.kts"  -o \
    -iname "gradle.properties"    -o \
    -iname "package.json"         -o \
    -iname "tsconfig.json"        -o \
    -iname "webpack.config.js"    -o \
    -iname "webpack.config.cjs"   -o \
    -iname "webpack.config.mjs"   -o \
    -iname "vite.config.js"       -o \
    -iname "vite.config.ts"       -o \
    -iname "rollup.config.js"     -o \
    -iname "rollup.config.mjs"    -o \
    -iname "requirements.txt"     -o \
    -iname "constraints.txt"      -o \
    -iname "pyproject.toml"       -o \
    -iname "Pipfile"              -o \
    -iname "Pipfile.lock"         -o \
    -iname "poetry.lock"          -o \
    -iname ".gitignore"           -o \
    -iname ".gitattributes"       -o \
    -iname ".editorconfig"        -o \
    -iname ".prettierrc"          -o \
    -iname ".prettierrc.*"        -o \
    -iname ".eslintrc"            -o \
    -iname ".eslintrc.*"          -o \
    -iname ".flake8"              -o \
    -iname ".pylintrc"            -o \
    -iname ".yamllint"            -o \
    -iname ".dockerignore"        -o \
    -iname ".gitlab-ci.yml"       -o \
    \
    ##### ДОКУМЕНТАЦИЯ / ТЕКСТ
    -iname "*.md"      -o \
    -iname "*.rst"     -o \
    -iname "*.adoc"    -o \
    -iname "*.org"     -o \
    -iname "*.txt" \
  \) \
  -print0 | while IFS= read -r -d '' file; do
    rel="${file#./}"
    rel="${rel:-.}"
    {
      printf '===== FILE: %s =====\n' "$rel"
      cat "$file"
      printf '\n===== END FILE: %s =====\n\n' "$rel"
    } >> "$OUT"
  done
