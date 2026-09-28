# Hướng dẫn dùng multi-agent-blog với Gemini (nhánh feat/gemini-adapter)

Nhánh này port từ claude-blog v2.2.0 sang Gemini CLI. Know-how giữ nguyên 100%, chỉ thay lớp vỏ.

## 0. Yêu cầu

- Ubuntu 22.04/24.04/26.04 hoặc Windows + WSL, Python 3.11+, Git, Node 20+
- Gemini CLI: `npm install -g @google/gemini-cli`
- API key: `https://aistudio.google.com/apikey`

## 1. Clone nhánh gemini

```bash
git clone -b feat/gemini-adapter https://github.com/teamseohpvn/claude-vi-t-b-i-chu-n-seo-EEAT.git multi-agent-blog
cd multi-agent-blog
```

## 2. Cài vào ~/.gemini

```bash
chmod +x installers/install-gemini.sh
./installers/install-gemini.sh
ls ~/.gemini/skills/blog/
ls ~/.gemini/agents/ | grep blog
pip3 install -r requirements.txt --break-system-packages
pip3 install patchright playwright --break-system-packages
python3 -m patchright install chromium --with-deps
```

## 3. Login Gemini

```bash
export GEMINI_API_KEY="AIza..."
echo 'export GEMINI_API_KEY="AIza..."' >> ~/.bashrc
gemini -m gemini-2.5-pro --help
```

Khuyên dùng model `gemini-2.5-pro` cho viết + review, `gemini-2.5-flash` cho research/brief rẻ.

## 4. Dùng cho site dầu công nghiệp (step by step)

Mỗi site tạo 1 thư mục riêng để giữ BRAND/VOICE:

```bash
mkdir -p ~/site-dau-cong-nghiep && cd ~/site-dau-cong-nghiep
gemini -m gemini-2.5-pro
```

Trong prompt `gemini>` gõ lần lượt, mỗi bước duyệt rồi mới sang bước sau:

**Step 1 - Nạp orchestrator:**

```text
Đọc adapters/gemini/GEMINI.md và skills/blog/SKILL.md trong ~/multi-agent-blog. Từ giờ route mọi lệnh /blog theo đó.
```

**Step 2 - Brand (1 lần duy nhất):**

```text
/blog brand init
```

Trả lời như mẫu dầu thủy lực ISO VG 32/46/68, đối tượng kỹ sư bảo trì Bình Dương/Đồng Nai. Xong kiểm tra `/blog brand show` phải thấy BRAND.md + VOICE.md.

**Step 3 - Strategy + calendar:**

```text
/blog strategy dau thuy luc cong nghiep
/blog discourse dau thuy luc ISO VG 46 --days 30
/blog calendar monthly
```

**Step 4 - Vòng đời 1 bài:**

```text
/blog brief Dau thuy luc ISO VG 46 la gi, cach chon cho may ep nhua
/blog outline Dau thuy luc ISO VG 46 cho may ep nhua
/blog write Dau thuy luc ISO VG 46 la gi, cach chon cho may ep nhua --format mdx --words 2500
/blog analyze ./output/bai-viet.md
/blog seo-check ./output/bai-viet.md
/blog geo ./output/bai-viet.md
/blog factcheck ./output/bai-viet.md
/blog schema ./output/bai-viet.md
```

**Step 5 - Mở rộng:**

```text
/blog image generate mo ta anh that
/blog audio generate ./output/bai-viet.md
/blog repurpose ./output/bai-viet.md
```

**Step 6 - Bài cũ:**

```text
/blog audit content/blog/
/blog rewrite content/blog/bai-cu.md
```

## 5. 5-gate trên Gemini chạy thế nào

1. Gate 1: `python3 ~/.gemini/scripts/blog_preflight.py --gate 1`
2. Gate 2: render .md -> .html/.pdf + hero, thiếu là block
3. Gate 3: patchright chụp 375/768/1280, JSON-LD valid
4. Gate 4: reviewer chấm >=90 và 0 lỗi P0, lặp tối đa 3 lần
5. Gate 5: `python3 ~/.gemini/scripts/blog_preflight.py --gate 5`, link phải 200

Nếu gate fail 3 lần, Gemini phải dừng và trình diagnostic, không giao draft.

## 6. Map lệnh Claude -> Gemini khi đọc SKILL.md gốc

| Claude | Gemini CLI |
|---|---|
| Task(blog-researcher/writer/reviewer) | làm tuần tự inline trong cùng session |
| Read/Write/Edit/Glob/Grep/Bash | read_file/write_file/edit/glob/grep/run_shell |
| WebFetch/WebSearch | web_fetch/web_search |
| $HOME/.claude/scripts | $HOME/.gemini/scripts (GEMINI_BLOG_SCRIPTS_DIR) |
| claude plugin validate . | bỏ qua |

## 7. Lỗi hay gặp

- `No such file ~/.gemini/skills/blog` -> chưa chạy install-gemini.sh
- Gemini chấm lỏng (cho qua bài <90) -> ép: `chấm nghiêm theo quality-scoring.md, block dưới 90`
- Thiếu chromium -> chạy lại `python3 -m patchright install chromium --with-deps`
- Muốn rẻ: research bằng flash, write/review bằng pro
