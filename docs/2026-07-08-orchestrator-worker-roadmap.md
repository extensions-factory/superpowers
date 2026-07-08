# Roadmap: Claude Orchestrator + Multi-Worker cho Superpowers (fork riso-tech)

> Ngày: 2026-07-08 (v2 — viết lại sau khi audit trực tiếp toàn bộ skills và hoàn thành Phase 1)
> Bối cảnh: Claude Code là interface duy nhất developer làm việc (orchestrator/architect).
> Worker: Codex (bridge `codex-plugin-cc` đã có), Antigravity CLI (bridge `agy-plugin-cc` sẽ xây sau, cùng kiến trúc).
> Thay quy trình thủ công "copy output worker A → worker B review → đưa link worker C triển khai" bằng điều phối tự động qua bridge.

---

## 1. Phân tích: fork đã có sẵn phần lớn hạ tầng orchestration

Các customization `riso-tech` cộng với hạ tầng upstream trong fork chính là các **primitive điều phối** mà mô hình orchestrator cần — đã xác minh từng cái trong code:

| Primitive có sẵn | Nằm ở đâu | Vai trò trong mô hình mới |
|---|---|---|
| Truy vết Spec → Plan → Code qua `US-n` + GIVEN/WHEN/THEN | `spec-template.md`, `plan-template.md`, US Checkpoint | **Worker contract**: task giao cho worker nào cũng có acceptance criteria máy-kiểm-được |
| Giao thức trạng thái `DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED` | `subagent-driven-development` (SDD), mục Handling Implementer Status | Chuẩn báo cáo chung — worker ngoài chỉ cần tuân cùng giao thức |
| Giao thức **file handoff**: task-brief file, report file, review package — "không paste vào context, đưa đường dẫn" | SDD mục File Handoffs + `scripts/task-brief`, `scripts/review-package`; `requesting-plan-refine` (findings file) | Interface trao đổi liên-vendor có sẵn; bridge protocol chỉ việc tuân theo |
| Progress ledger sống sót qua compaction | SDD mục Durable Progress: `.superpowers/sdd/progress.md` | Thêm cột `worker/profile/job-id` là thành sổ cái cross-vendor |
| Chính sách chọn model 3 mức: mechanical / integration / architecture-design | SDD mục Model Selection | Map 1:1 thành 3 subkey `implementer.*` trong routing — không phát minh taxonomy mới |
| Prompt template hóa từng vai | `implementer-prompt.md`, `task-reviewer-prompt.md`, `plan-reviewer.md`, `code-reviewer.md` | Điểm cắm: đổi đích dispatch, giữ nguyên nội dung prompt |
| `roadmap.json` Epic→Feature→US | `brainstorming/roadmap.md` | Theo dõi tiến độ sản phẩm xuyên worker |
| Kỷ luật tạo/sửa skill bằng TDD (RED-GREEN-REFACTOR, Iron Law) | `writing-skills` | Mọi chỉnh sửa skill trong roadmap này phải có baseline test trước khi viết |

**Kết luận:** KHÔNG fork đôi Superpowers. Chỉ cần (a) một tầng định tuyến worker cắm vào các dispatch point có sẵn, (b) một bản build rút gọn cho phía worker. Quy trình SDLC, template, giao thức giữ nguyên.

### Catalog dispatch point thực tế (audit từ code, không phải ước lượng)

Toàn bộ SDLC có đúng **8 role trên 5 skill** có dispatch subagent:

| Role key | Dispatch point (skill) | Ghi chú |
|---|---|---|
| `researcher` | `project-kickoff` Phase 1 research fan-out (×4, qua `dispatching-parallel-agents`) | read-only, chạy song song |
| `plan-reviewer` | `requesting-plan-refine` | read-only, kết quả về `.superpowers/plan-refine/<plan>-findings.md` |
| `implementer.mechanical` | SDD — task 1-2 file, spec đầy đủ | tier cheap |
| `implementer.integration` | SDD — task đa file, cần judgment | tier standard |
| `implementer.design` | SDD — task kiến trúc | tier **max** (SDD: "most capable model") |
| `fixer` | SDD — fix dispatch cho findings Critical/Important | mang implementer contract; findings mức integration/design thì dùng role implementer tương ứng |
| `task-reviewer` | SDD — per-task review (spec compliance + code quality) | **cross-vendor** với vendor implement task đó |
| `code-reviewer` | `requesting-code-review` (standalone + final whole-branch review của SDD) | **cross-vendor**, final review tier max |

Các skill KHÔNG có dispatch (không đụng tới): `brainstorming` (self-review là checklist tự chạy), `writing-plans` (Spec Alignment Check "not a subagent dispatch"), `executing-plans` (đường không-subagent, ngoài scope routing), `finishing-a-development-branch`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`.

Phát hiện khi audit: `writing-plans/plan-document-reviewer-prompt.md` là **file mồ côi** — không skill nào tham chiếu (đã bị cặp plan-refine thay thế). Dọn ở Phase 2.

### Ma trận cross-review (quy tắc cứng)

```
Quy tắc 1: Vendor viết code ≠ vendor review code đó (task-reviewer lẫn code-reviewer)
Quy tắc 2: Plan do Claude viết → worker ngoài review plan (adversarial)
Quy tắc 3: Review mâu thuẫn → Claude orchestrator trọng tài (đây là việc của
           orchestrator, KHÔNG phải một role dispatch); mâu thuẫn scope/spec → escalate người
Quy tắc 4: Verification do Claude tự chạy tại chỗ — không tin evidence worker tự khai
Quy tắc 5: Hết vendor hợp lệ cho reviewer → DỪNG và escalate, không bao giờ
           lặng lẽ self-review cùng vendor
```

---

## 2. ROADMAP

### ✅ Phase 1 — Worker Routing Layer — **HOÀN THÀNH 2026-07-08**

Đã giao, theo đúng chu trình `writing-skills` (RED baseline → viết skill → GREEN verify):

| Deliverable | Trạng thái |
|---|---|
| Skill `skills/delegating-to-workers/SKILL.md` (568 từ, description chỉ chứa trigger theo chuẩn SDO) | ✅ |
| `skills/delegating-to-workers/bridge-dispatch.md` — giao thức bridge: workspace `.superpowers/dispatch/`, prompt-file/report-file, bảng lệnh Codex theo role, status mapping, resume discipline | ✅ |
| `skills/delegating-to-workers/worker-contract.md` — contract vendor-neutral: scope, TDD bắt buộc (implementer), read-only (reviewer/researcher), evidence nguyên văn, dòng `STATUS:` cuối file | ✅ |
| `skills/delegating-to-workers/routing.example.json` — schema reference 8 role | ✅ |
| `~/.agents/routing.json` — bản live trên máy (antigravity `available: false` chờ bridge) | ✅ |

**Kết quả test:**
- RED (subagent không skill, có áp lực deadline + bridge lỗi): tự tuân cross-vendor khi routing.json được đưa sẵn → phần kỷ luật không cần bulletproof nặng; cái không thể tự biết là giao thức bridge và thói quen tra registry → skill viết dạng technique + reference.
- GREEN (subagent đọc skill từ disk, 3 scenario): resolve role + tier đúng, dựng đúng file paths, không bịa `--profile`, cross-vendor walk đúng thứ tự, và edge case "Claude viết + codex cooldown" → **dừng escalate thay vì self-review**. Không lộ loophole → chưa cần REFACTOR.

**Còn nợ nghiệm thu:** smoke test sống (dispatch thật qua bridge, giả lập fail để xem fallback) — phải chạy trong phiên Claude Code có cài `codex-plugin-cc`. Làm đầu Phase 2.

**Thiết kế chốt:**
- Registry tách khỏi secrets: `routing.json` (routing) vs `profiles.json` (auth). Không có `routing.json` → mọi role về internal subagent như cũ (zero-config, không regression).
- Block `workers` (bridge + available, thứ tự khai báo = thứ tự ưu tiên cross-vendor) + `tiers` (cheap/standard/max → model theo vendor; `null` = để bridge dùng default account) + `roles` (8 key, `model` override `tier`, `fallback` dạng `vendor:tier`).
- Reviewer role qua Codex ưu tiên `/codex:review`, `/codex:adversarial-review` (read-only by construction); `codex:codex-rescue` cho implementer/fixer/task-reviewer/researcher cần prompt template riêng.

### Phase 0 — Vận hành tay với bridge (song song, ngay bây giờ)

Vẫn giữ nguyên giá trị dù Phase 1 xong — đây là cách sinh dữ liệu thật trước khi Phase 2 tự động hóa:

- Sau `writing-plans`: `/codex:adversarial-review` soát plan (US slicing, task ordering, thiếu sót) thay vòng plan-refine tay.
- Sau đợt Claude tự code: `/codex:review --background`.
- `~/.agents/profiles.json` đã có 6 profile / 3 vendor + weighted rotation — chỉnh weight theo quota thật.
- Bật stop-review gate + `gateProfile` cho phiên coding dài.

### Phase 2 — Cắm routing vào các dispatch point (~1-2 tuần)

**Ràng buộc quy trình (mới, quan trọng):** mỗi edit skill là một chu trình `writing-skills` — RED baseline trước (chứng kiến hành vi sai khi chưa có edit), edit tối thiểu, GREEN verify. Không batch nhiều skill rồi test một thể.

**Bước 0 — smoke test sống Phase 1** (tiêu chí nghiệm thu còn nợ): 1 task mechanical thật qua `codex:codex-rescue` với prompt-file/report-file; 1 lần giả lập bridge fail để xem fallback walk + ledger note.

**Thay đổi theo file** (mọi sửa đổi bọc `<!-- created by riso-tech -->` để giữ sạch rebase upstream):

| File | Sửa gì |
|---|---|
| `skills/subagent-driven-development/SKILL.md` | (a) Mục Model Selection: thêm bước tra registry qua `delegating-to-workers` trước khi tự chọn model; (b) các bước dispatch implementer/task-reviewer/fixer/final-review: chỉ dẫn route qua skill đó khi `routing.json` tồn tại; (c) mục Durable Progress: format dòng ledger thêm `worker=<vendor> profile=<name> job=<id>` |
| `skills/subagent-driven-development/implementer-prompt.md` | Ghi chú: khi dispatch ra bridge, template này nằm trong prompt-file kèm worker-contract (không đổi nội dung template — File Handoffs đã tương thích sẵn: brief path + report path) |
| `skills/subagent-driven-development/task-reviewer-prompt.md` | Tương tự + 1 dòng cho reviewer biết vendor đã implement (tránh giả định style) |
| `skills/requesting-plan-refine/SKILL.md` | Bước 3 (Dispatch): tra role `plan-reviewer` trong registry; nếu ra bridge → `/codex:adversarial-review` với focus text trỏ plan/spec, kết quả vẫn ghi về `.superpowers/plan-refine/<plan>-findings.md` → `receiving-plan-refine` **không cần sửa** |
| `skills/requesting-code-review/SKILL.md` | Bước 2 (Dispatch): tra role `code-reviewer`; cross-vendor với tác giả chính của diff; tùy chọn dual-review (2 vendor cùng review, orchestrator hợp nhất) cho diff rủi ro cao |
| `skills/project-kickoff/SKILL.md` | Phase 1 research fan-out: tra role `researcher` (mặc định giữ internal claude — chỉ đổi khi registry nói khác) |
| `skills/writing-plans/plan-template.md` | Mỗi Task thêm dòng `Complexity: mechanical\|integration\|design` — planner phân loại lúc viết, orchestrator dispatch máy móc |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | **Xóa** (file mồ côi, đã bị plan-refine thay thế) — kiểm tra grep toàn repo trước khi xóa |

**Nghiệm thu Phase 2:** chạy trọn SDD cho 1 plan ≥5 task: ≥3 task Codex implement, 100% task được review bởi vendor khác vendor viết, ledger có đủ cột worker/profile/job, và 1 lần fallback có ghi lý do.

### Phase 3 — Worker Profile Build (song song Phase 2, ~3-5 ngày)

Worker chỉ nhận kỹ năng **thi hành**, không nhận kỹ năng ra-quyết-định:

```
scripts/build-worker-profile.sh
  → whitelist: test-driven-development, systematic-debugging,
    verification-before-completion, receiving-code-review, using-superpowers (rút gọn)
  → loại: brainstorming, writing-plans, project-kickoff, subagent-driven-development,
    executing-plans, dispatching-parallel-agents, delegating-to-workers,
    finishing-a-development-branch, cặp plan-refine, writing-skills
  → tận dụng script Codex portal packaging ĐÃ CÓ trong fork (thêm tham số whitelist)
  → cài vào từng CODEX_HOME của các profile trong profiles.json
```

Kèm bootstrap/`AGENTS.md` phía worker: "Bạn là worker trong pipeline. Nhận task từ orchestrator. Không mở rộng scope. Không refactor ngoài task. Kết thúc bằng STATUS line." (trùng khớp worker-contract.md — contract trong prompt là nguồn chính, bootstrap là lưới đỡ).

**Lý do cắt skill điều phối khỏi worker:** worker không có quyền merge/PR/đổi hướng — ranh giới orchestrator/worker; đồng thời giảm token bootstrap mỗi lần rescue.

**Nghiệm thu:** `CODEX_HOME=<profile> codex` thấy đúng bộ skill rút gọn; 1 task TDD qua rescue tuân RED-GREEN-REFACTOR và trả STATUS line.

### Phase 4 — Bridge thứ hai: `agy-plugin-cc` (~2-3 tuần, sau khi Phase 2 ổn định)

Cross-review đa vendor thật: GPT ↔ Gemini(AGY) review chéo, Claude trọng tài.

- Việc đầu tiên (quyết định độ khó toàn phase): khảo sát giao diện điều khiển của Antigravity CLI, map sang kiến trúc broker/companion của `codex-plugin-cc` (`app-server-broker.mjs`, `codex-companion.mjs`).
- Cùng schema `profiles.json` — các profile `agent: "antigravity"` đã khai sẵn trên máy (`agy-ultra`), scheduling block đã có sẵn mục antigravity.
- Cùng bộ lệnh `/agy:rescue|review|status|result|cancel|setup`, cùng giao thức STATUS/report-file → phía superpowers **chỉ sửa 1 chỗ**: flip `workers.antigravity.available = true` trong `routing.json` và thêm dòng lệnh AGY vào bảng trong `bridge-dispatch.md`. Không sửa skill nào của Phase 2.

**Nghiệm thu:** 1 plan có task Codex viết được AGY review và ngược lại; resume đúng account sở hữu thread.

### Phase 5 — Pipeline hóa & vận hành (liên tục sau Phase 4)

1. **Song song hóa:** task khác US, không phụ thuộc → dispatch background đồng thời trên các profile khác nhau; orchestrator dùng thời gian chờ để review task trước + cập nhật `roadmap.json` (bridge-dispatch.md đã quy định "wait productively" — đây là mở rộng có kỷ luật của nó).
2. **Quota-aware routing:** nối cooldown/scheduler-state của bridge vào bước resolve (worker cooldown = unavailable → fallback walk tự xử lý; nền tảng weighted round-robin + cooldownMinutes đã có trong profiles.json).
3. **Ledger + metrics:** khai thác các cột worker/model/rounds/findings trong `.superpowers/sdd/progress.md` → sau 5-10 feature, biết vendor nào review bắt lỗi thật nhiều nhất, chỉnh `routing.json` bằng số liệu thay vì cảm tính.
4. **Trọng tài có audit trail:** khi 2 review mâu thuẫn, orchestrator ghi file adjudication (finding, lập luận 2 bên, phán quyết, lý do) cạnh findings file.

---

## 3. Quyết định kiến trúc (chốt)

1. **Không fork đôi Superpowers** — 1 fork + routing layer + worker-profile build script. Tách bằng **build artifact**, không tách bằng repo.
2. **Giao thức có sẵn là chuẩn liên-vendor** — file handoff (brief/report/findings/review-package), STATUS protocol, US/GWT. Bridge protocol của Phase 1 tuân theo chúng, không phát minh mới.
3. **Diện tích sửa Phase 2 = 6 skill file + 1 template + 1 xóa file mồ côi** — routing đã nằm ở skill riêng (Phase 1 xong), các skill SDLC chỉ thêm chỉ dẫn "tra registry trước khi dispatch".
4. **Trọng tài không phải role dispatch** — đó là việc của orchestrator; registry chỉ route những gì được dispatch.
5. **Mọi edit skill đi qua writing-skills TDD** — RED baseline → edit tối thiểu → GREEN verify, từng skill một, không batch.
6. **Thứ tự: P0 (tay, song song) → ✅P1 routing → P2 cắm skill → P3 worker build → P4 bridge AGY → P5 tối ưu.**
