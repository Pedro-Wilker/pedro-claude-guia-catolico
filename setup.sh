#!/usr/bin/env bash
# setup.sh — bootstrap Claude Code config num device novo
# Repo: pedro-claude-guia-catolico
# Uso: ./setup.sh

set -euo pipefail

echo "=== pedro-claude-guia-catolico setup ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
echo "Project root: $PROJECT_ROOT"

detect_memory_path() {
	if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
		echo "/c/Users/$USER/.claude/projects"/*/memory
	else
		echo "$HOME/.claude/projects"/*/memory
	fi
}

MEMORY_PATHS=( $(detect_memory_path) )

if [ ${#MEMORY_PATHS[@]} -eq 0 ] || [ ! -d "${MEMORY_PATHS[0]}" ]; then
	echo "ERRO: memory path não encontrado. Claude Code já rodou neste device?"
	exit 1
fi

MEMORY_DIR="${MEMORY_PATHS[0]}"
echo "Memory dir: $MEMORY_DIR"

echo ""
echo "[1/3] Sincronizando memory/"
if [ -f "$SCRIPT_DIR/memory/MEMORY.md" ]; then
	cp -v "$SCRIPT_DIR/memory/MEMORY.md" "$MEMORY_DIR/"
	for f in "$SCRIPT_DIR/memory/"*.md; do
		if [ "$(basename "$f")" != "MEMORY.md" ]; then
			cp "$f" "$MEMORY_DIR/"
		fi
	done
fi

SETTINGS_DIR="$PROJECT_ROOT/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.local.json"

echo ""
echo "[2/3] Gerando settings.local.json"

mkdir -p "$SETTINGS_DIR"

if [ -f "$SETTINGS_FILE" ]; then
	echo "settings.local.json já existe — mantendo."
else
	if [ -f "$SCRIPT_DIR/settings.json.template" ]; then
		cat "$SCRIPT_DIR/settings.json.template" \
			| sed "s|__PROJECT_ROOT__|$PROJECT_ROOT|g" \
			| sed "s|__HOME__|$HOME|g" \
			> "$SETTINGS_FILE"
		echo "Criado: $SETTINGS_FILE"
	fi
fi

echo ""
echo "[3/3] Verificando CLAUDE.md"

if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
	echo "AVISO: CLAUDE.md não está na raiz."
	echo "  cp pedro-claude-guia-catolico/CLAUDE.md ./CLAUDE.md"
	echo "  ou"
	echo "  ln -s pedro-claude-guia-catolico/CLAUDE.md CLAUDE.md"
else
	echo "CLAUDE.md OK"
fi

echo ""
echo "=== Setup completo ==="