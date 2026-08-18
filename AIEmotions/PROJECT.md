# Project: AIEmotions — Emotion-Driven Writing Prompts

## 🎯 The Game Plan
| Category | What we are doing |
| :--- | :--- |
| **Project Goal** | A writing app where prompts are short "Verb-ing + Object" phrases, each tagged with the emotion(s) it's meant to evoke. The app learns which emotions you gravitate toward and biases future prompts accordingly. |
| **Main Focus** | Keep it strictly local — Swift's native Foundation Models framework generates prompts entirely on-device. |
| **What we are skipping** | Reading other users' published posts. `readPublished(id:)` exists on the class diagram but is intentionally NOT implemented — there's no backend to fetch from yet. "Published" currently just means "moved out of drafts, kept locally." |

*(Original sandbox goal — testing Swift's native Foundation Model integration — is still true; it's just now in service of a concrete app instead of a blank test harness.)*

## 🛠️ The Tech Setup
| Component | What we are using | Simple Explanation |
| :--- | :--- | :--- |
| **User Interface** | SwiftUI, single-screen home (no tab bar) | `HomeView` shows Write (and, once today's writing is done, Read), with Profile behind a top-right icon — see navigation section below. |
| **The Brains** | `FoundationModels` (`LanguageModelSession`, `@Generable`/`@Guide`) | Generates 3 prompts a day, each a short phrase + emotion tags, fully on-device. Falls back to a small curated prompt bank if the model is unavailable. |
| **Local Memory** | SwiftData (`User`, `Post`) | `User` is the single local profile; `Post` covers both drafts and published entries via an `isPublished` flag. |
| **Persistence for identity** | `identifierForVendor` + Keychain (`DeviceIdentity`) | Keychain survives reinstalls, so `deviceID` stays stable. |

## 🧭 Navigation (no more tab bar)
- **`HomeView`** is the app root. Top-right toolbar icon → `ProfileView`. Center: a **Write** button, always present.
- **Start of day:** only Write is interactive. Tagline: *"Start writing and see where it takes you!"*
- **After the day's one writing session is done** (`User.hasWrittenToday` — see below): Write gets a hand-drawn `ScribbleOverlay` strike across it and is disabled; the tagline changes to *"Come back tomorrow to write something new!"*; a **Read** button is revealed underneath with its own tagline, *"Discover a piece written by someone else!"*
- **`ReadView`** (pushed from Read) is a placeholder for now — reading *other* users' posts needs a backend, which is explicitly out of scope (see `readPublished(id:)` note below). It's honest about that and shows the user's own published posts as a stand-in.
- **`ProfileView`** now also hosts what used to be separate Drafts/Published tabs, switched via an in-page **Publish (n) / Drafts (n)** segmented toggle (`PostListContent`, reused by both Profile and Read).

## ✍️ Once-per-day writing
- `User.hasWrittenToday` / `markWrittenToday()` (backed by a `lastWriteDate` timestamp, same day-boundary pattern as the daily prompts) — set the moment `Post.saveAsDraft` runs, so **either** saving a draft **or** publishing counts as "today's writing" and locks Write until the next calendar day.
- The writing flow itself (`WritingView`) matches the mockup: prompt title + shuffle link with a live `(remaining/3)` counter, a text box with an inline "Camera" attach button pinned to its bottom edge, a tip banner (plus a red "Keep writing!" nudge under the minimum), and a "Done" button that's disabled until the minimum length is met. Tapping Done surfaces a "Save for later or publish now?" confirmation overlay rather than two always-visible buttons — matching the modal in the mockup — and either choice dismisses straight back to Home.

## 🧩 How it maps to the class diagram
- **User** → `Models/User.swift` (SwiftData `@Model`). `emotionProfile: [String: Int]` is the running tally PromptManager reads to bias generation. `loadDrafts()`/`loadPublished()` are filtered views over the live `posts` relationship rather than separate fetches.
- **Post** → `Models/Post.swift`. `promptUsed` is flattened into `promptVerb` / `promptFullText` / `promptEmotionData` (a durable snapshot) instead of holding a live `PromptData` reference, since prompts are ephemeral. `saveAsDraft` is a static factory (inserts + returns a new `Post`); `publish()` flips the existing draft's state.
- **PromptManager** → `Services/PromptManager.swift`. Matches the diagram's 1→3 relationship, but the 3 `PromptData` now live as persisted state on `User` (`todaysPrompts`) rather than transient state on the manager itself — needed so the set survives app relaunches for the same day. `PromptManager` is the stateless generation/mutation layer over that persisted state (`generateDailyPromptsIfNeeded`, `discardPrompt`, `generateDiscoveryPrompt`), all backed by `LanguageModelSession`.
- **PromptData** → `Models/PromptData.swift`. Kept as a plain `Codable` struct (not a SwiftData model) since it's regenerated every session — only what the user actually writes gets persisted, via the `Post` snapshot above.

## 🔁 The emotion feedback loop (revised)

**Daily prompts, not session prompts.** `PromptManager.generateDailyPromptsIfNeeded(for:)` generates exactly 3 prompts once per calendar day and persists them on `User` (`todaysPrompts`, backed by encoded JSON + a date stamp — see `User.swift`). The screen shows **one prompt at a time** (the first of the set), not all 3 side by side.

**Shuffling deletes, it doesn't replace.** Tapping the trash icon on a prompt calls `PromptManager.discardPrompt(_:for:)`, which permanently removes it from today's set — no new prompt is generated to fill the gap. 3 → 2 → 1, and the last remaining prompt can't be discarded (the UI disables the button; the model layer also refuses the removal as a safety net). The set refreshes to a new batch of 3 the next calendar day.

**Exploration before personalization.** `User.isEmotionProfileUnlocked` is `true` once *any single emotion* has been written from 5+ times. Below that threshold, `PromptManager` explicitly asks the model for a random, broad emotional spread — the profile isn't allowed to steer anything yet, so the user gets a real tour of different feelings before the app starts narrowing in.

**Discovery button (post-unlock, once/day, only after shuffles are exhausted).** Once unlocked, the daily 3 *are* biased toward the user's top emotions as before. A separate "Discover" option only appears once `User.hasExhaustedTodaysShuffles` is true (i.e. the user has shuffled down to their last mandatory prompt) — capped at once per calendar day (`User.hasUsedDiscoveryToday` / `markDiscoveryUsedToday()`). Its generation prompt gives the model a **strict priority order**: (1) an emotion the user has *never* scored at all — the preferred outcome, and what the instruction tells the model to reach for unless it's genuinely stuck; only if that's not possible does it (2) fall back to the user's single lowest-scored emotion. The result is appended to today's set rather than replacing anything.

**Weighting still comes from writing, not just viewing.** Saving a draft or publishing calls `User.updateEmotionWeight(_:)` for each emotion tag on the prompt actually used, via `Post.saveAsDraft`. Profile tab visualizes the resulting tally as a simple bar breakdown.

**Anti-spam floor.** Save Draft / Publish are disabled until the trimmed text is at least 10 characters (`WritingView.minimumCharacterCount`), with a live counter under the editor.

## 🪜 Step-by-Step Roadmap (revised)
| Step | Phase | The Breakdown | Status |
| :--- | :--- | :--- | :--- |
| **1** | **The Skeleton** | SwiftUI shell, models (`User`, `Post`, `PromptData`), `DeviceIdentity`. | ✅ Done |
| **2** | **The AI Hookup** | `PromptManager` wired to `FoundationModels` with `@Generable` schema (`GeneratedPrompt` / `GeneratedPromptBatch`), plus an offline fallback bank. | ✅ Done |
| **3** | **The Writing Flow** | `WritingView`: text editor, optional photo attach (`PhotosPicker`), save-draft/publish. | ✅ Done |
| **4** | **The Save State** | SwiftData persistence for `User`/`Post`; `PostListView` for both Drafts and Published. | ✅ Done |
| **5** | **The Feedback Loop** | Emotion-weight updates on save/publish; Profile tab emotion breakdown bars; bias prompt generation off top emotions. | ✅ Done |
| **6** | **Daily prompt lifecycle** | Exactly 3 prompts/day, persisted on `User`; shuffle = permanent delete (no replacement), floor of 1 that can't be discarded; refreshes next calendar day. | ✅ Done this pass |
| **7** | **Exploration-first weighting** | Bias only kicks in once an emotion hits a weight of 5+ (`User.isEmotionProfileUnlocked`); random spread before that. | ✅ Done this pass |
| **8** | **Discovery button** | Once-per-day, post-unlock-only button that appends one extra prompt targeting an unexplored/lowest-scored emotion. | ✅ Done this pass |
| **9** | **Anti-spam floor** | 10-character minimum on Save Draft / Publish, with a live counter. | ✅ Done this pass |
| **10** | **Bug fix** | `PostListView`'s `.onDelete` was applying to both drafts and published lists; now gated to drafts only inside the closure. | ✅ Fixed this pass |
| **11** | **Home redesign** | Removed the tab bar entirely. `HomeView` is now the root: Write button (with `ScribbleOverlay` strike + disabled state once written today), conditionally-revealed Read button, Profile behind a top-right toolbar icon. | ✅ Done this pass |
| **12** | **Once-per-day writing** | `User.hasWrittenToday`/`markWrittenToday()`; either saving a draft or publishing locks Write until the next calendar day. `WritingView` now dismisses itself after either action. | ✅ Done this pass |
| **13** | **Drafts/Published → Profile only** | `PostListView` split into `PostListContent` (reusable list) + a thin standalone wrapper; `ProfileView` now hosts both via an in-page Publish/Drafts toggle; `ReadView` reuses the same content for its own-posts stand-in. | ✅ Done this pass |
| **14** | **Discovery priority + gating rework** | Discovery generation now strictly prioritizes a never-scored emotion over the lowest-scored one (was previously a soft either/or), and the button is now gated on `hasExhaustedTodaysShuffles` (only 1 prompt left) rather than being available any time post-unlock. | ✅ Done this pass |
| **15** | **Writing screen redesign** | Rebuilt `WritingView` to match the mockup: prompt title + shuffle link w/ `(n/3)` counter, in-box "Camera" attach button, tip banner + red under-minimum nudge, "Done" → save/publish confirmation overlay. | ✅ Done this pass |
| **16** | **Next up** | Real device testing of `FoundationModels` availability/perf and the daily-reset boundary (device timezone/midnight edge cases); optional export (share sheet) for published posts; eventually a real backend for `ReadView`/`readPublished(id:)`. | ⏳ Not started |

## ⚠️ Things worth double-checking on your machine
- `FoundationModels` requires iOS 26+ on Apple Intelligence–eligible hardware; on the Simulator or unsupported devices, `SystemLanguageModel.default.availability` won't be `.available` and the app will silently use the fallback prompt bank instead of crashing.
- If Xcode doesn't auto-link `FoundationModels`, add it manually under the target's *General → Frameworks, Libraries, and Embedded Content*.
- `Post.attachedImageData` / `User.profilePictureData` use `@Attribute(.externalStorage)` since photos can be large — no action needed, just noting why they're not inline blobs.
