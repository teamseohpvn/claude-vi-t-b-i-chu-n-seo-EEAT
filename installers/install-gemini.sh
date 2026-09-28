#!/usr/bin/env bash
set -euo pipefail
# multi-agent-blog — Gemini installer
# Port từ install.sh (claude-blog v2.2.0, MIT). Copy skills/agents/scripts
# sang ~/.gemini/ thay vì ~/.claude/. Bỏ `claude plugin validate`.
VERSION="2.2.0-gemini.1"

copy_tree() {
    local src="$1" dest="$2"
    [ -d "${src}" ] || return 0
    mkdir -p "${dest}"
    while IFS= read -r -d '' f; do
        mkdir -p "${dest}/$(dirname "${f}")"
        cp "${src}/${f}" "${dest}/${f}"
    done < <(cd "${src}" && find . -type d -name '__pycache__' -prune -o -type f ! -name '*.pyc' -print0)
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[ -d "${SCRIPT_DIR}/skills/blog" ] || SCRIPT_DIR="$(pwd)"
GEMINI_DIR="${HOME}/.gemini"
SKILL_DIR="${GEMINI_DIR}/skills"
AGENT_DIR="${GEMINI_DIR}/agents"
SCRIPT_DEST="${GEMINI_DIR}/scripts"
MANIFEST="${GEMINI_DIR}/multi-blog-manifest.txt"

echo "multi-agent-blog (Gemini) ${VERSION}"
mkdir -p "${SKILL_DIR}/blog" "${AGENT_DIR}" "${SCRIPT_DEST}"
: >"${MANIFEST}.tmp"

cp "${SCRIPT_DIR}/skills/blog/SKILL.md" "${SKILL_DIR}/blog/SKILL.md"
echo "${SKILL_DIR}/blog" >>"${MANIFEST}.tmp"
copy_tree "${SCRIPT_DIR}/skills/blog/references" "${SKILL_DIR}/blog/references"
copy_tree "${SCRIPT_DIR}/skills/blog/templates" "${SKILL_DIR}/blog/templates"
[ -f "${SCRIPT_DIR}/data/google-updates.json" ] && { mkdir -p "${SKILL_DIR}/blog/data"; cp "${SCRIPT_DIR}/data/google-updates.json" "${SKILL_DIR}/blog/data/"; }
cp "${SCRIPT_DIR}/adapters/gemini/GEMINI.md" "${SKILL_DIR}/blog/GEMINI.md"

count=0
for d in "${SCRIPT_DIR}/skills/"*/; do
    n="$(basename "${d}")"; [ "$n" = "blog" ] && continue
    case "$n" in ''|*[!a-z0-9-]* ) echo "skip: $n" >&2; continue;; esac
    [ -f "${d}SKILL.md" ] || continue
    mkdir -p "${SKILL_DIR}/${n}"
    cp "${d}SKILL.md" "${SKILL_DIR}/${n}/SKILL.md"
    echo "${SKILL_DIR}/${n}" >>"${MANIFEST}.tmp"
    for p in references scripts assets templates; do copy_tree "${d}${p}" "${SKILL_DIR}/${n}/${p}"; done
    count=$((count+1))
done
echo "sub-skills: ${count}"

for f in "${SCRIPT_DIR}/agents/"*.md; do
    [ -f "$f" ] || continue
    cp "$f" "${AGENT_DIR}/$(basename "$f")"
    echo "${AGENT_DIR}/$(basename "$f")" >>"${MANIFEST}.tmp"
done
for f in "${SCRIPT_DIR}/scripts/"*.py; do
    [ -f "$f" ] || continue
    cp "$f" "${SCRIPT_DEST}/$(basename "$f")"; chmod +x "${SCRIPT_DEST}/$(basename "$f")"
    echo "${SCRIPT_DEST}/$(basename "$f")" >>"${MANIFEST}.tmp"
done
mv "${MANIFEST}.tmp" "${MANIFEST}"
if [ -f "${SCRIPT_DIR}/requirements.txt" ] && command -v pip3 >/dev/null 2>&1; then
    pip3 install -r "${SCRIPT_DIR}/requirements.txt" 2>&1 | tail -n 3 || echo "pip install: xem log, chạy tay pip3 install -r requirements.txt"
fi
echo "Done. Skills: ${SKILL_DIR}/blog | Manifest: ${MANIFEST}"
echo "Next: export GEMINI_API_KEY=... ; gemini -m gemini-2.5-pro"
