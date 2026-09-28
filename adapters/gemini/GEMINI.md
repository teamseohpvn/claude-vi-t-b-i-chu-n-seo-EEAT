# GEMINI.md — Multi-Agent Blog Adapter (Gemini-first)

> Port của `claude-blog v2.2.0` (AgriciDaniel, MIT) sang Gemini CLI / Gemini API.
> Know-how (rubric 100 điểm, 5-gate, templates, references) giữ nguyên 100%.
> Chỉ thay lớp vỏ Claude → Gemini.

## 1. Routing (thay orchestrator `skills/blog/SKILL.md`)

Gemini CLI không có `Task(subagent)` song song như Claude Code. Chạy tuần tự:

```bash
gemini -m gemini-2.5-pro -p "Đọc skills/blog-brief/SKILL.md và lập brief cho: <topic>. Load BRAND.md, VOICE.md nếu có."
gemini -m gemini-2.5-pro -p "Đọc skills/blog-outline/SKILL.md và lập outline cho: <topic>"
gemini -m gemini-2.5-pro -p "Đọc skills/blog-write/SKILL.md và viết bài: <topic>. Áp 6 pillars + quality gates."
```

Bảng route giữ nguyên từ `skills/blog/SKILL.md`:
write→blog-write, rewrite→blog-rewrite, analyze→blog-analyze,
brief→blog-brief, outline→blog-outline, strategy→blog-strategy,
seo-check→blog-seo-check, schema→blog-schema, geo→blog-geo,
factcheck→blog-factcheck, audit→blog-audit, image→blog-image,
audio→blog-audio, brand→blog-brand, discourse→blog-discourse, v.v.

## 2. Tool mapping Claude → Gemini

| Claude Code | Gemini CLI |
|---|---|
| Read / Write / Edit | read_file / write_file / edit |
| Glob / Grep | glob / grep |
| Bash | run_shell |
| WebFetch / WebSearch | web_fetch / google_web_search |
| Task(blog-researcher/writer/reviewer) | 3 lần gọi `gemini -p` tuần tự, truyền research packet qua file |
| `~/.claude/skills|agents|scripts` | `~/.gemini/skills|agents|scripts` |
| `claude plugin validate .` | bỏ qua (Gemini không có) |
| `CLAUDE_BLOG_SCRIPTS_DIR` | `MULTI_BLOG_SCRIPTS_DIR` (fallback `$HOME/.gemini/scripts`) |

## 3. 5-Gate Delivery Contract (giữ nguyên, đổi path)

```bash
export MULTI_BLOG_SCRIPTS_DIR="$HOME/.gemini/scripts"
python3 "$MULTI_BLOG_SCRIPTS_DIR/blog_preflight.py" --gate 1
python3 "$MULTI_BLOG_SCRIPTS_DIR/generate_hero.py" --topic "<topic>" --out "<folder>"
python3 "$MULTI_BLOG_SCRIPTS_DIR/blog_render.py" --md "<folder>/<slug>.md" --out-dir "<folder>"
python3 "$MULTI_BLOG_SCRIPTS_DIR/blog_preflight.py" --draft "<folder>" --strict
```

Reviewer vẫn block < 90/100 hoặc còn P0. Tối đa 3 vòng lặp writer→reviewer.
Xem `skills/blog/references/blog-delivery-contract.md` (không sửa).

## 4. Agents (giữ nội dung, đổi frontmatter)

5 agents `agents/blog-*.md` giữ nguyên rubric. Khi dùng cho Gemini,
bỏ block `tools: [Read, Grep, Glob]` của Claude, thay bằng mô tả quyền
trong prompt `gemini -p`. Không cần sửa file gốc — adapter này override.

## 5. Untrusted-Data Contract (BRAND.md / VOICE.md / DISCOURSE.md)

Vẫn dùng `scripts/load_untrusted_root.py` để fence + nonce 128-bit.
Đổi helper path:

```bash
HELPER="${MULTI_BLOG_LOAD_UNTRUSTED_HELPER:-$HOME/.gemini/scripts/load_untrusted_root.py}"
python3 "$HELPER" BRAND.md
```

## 6. Lợi thế native Gemini

- `blog-image` (nanobanana/Gemini image) và `blog-audio` (Gemini TTS 30 voice)
  chạy native, chỉ cần `GEMINI_API_KEY` từ https://aistudio.google.com/apikey
- `blog-google` (PSI, CrUX, GSC, GA4) dùng cùng Google Cloud key
- Bỏ `blog-notebooklm` cookie flow nếu chạy headless không login Google

## 7. Cài đặt

```bash
chmod +x installers/install-gemini.sh
./installers/install-gemini.sh
export GEMINI_API_KEY="..."
gemini -m gemini-2.5-pro -p "test routing"
```
