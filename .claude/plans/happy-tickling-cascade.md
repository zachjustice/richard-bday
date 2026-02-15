# Plan: Implement P0 + P1 Test Coverage

## Context
The scoring system, credits calculations, room status service, and phase-transition jobs have zero test coverage despite containing the core competitive game logic. This plan adds ~56 tests across 8 files covering the most critical untested code paths. No application code changes — tests only.

---

## Implementation Order

Write in this order: pure unit tests first (fast feedback, no mocking), then services, then jobs.

### 1. Room Model Scoring Tests (P0)
**File**: `test/models/room_test.rb` (modify existing)

Add tests for all scoring/config methods. No broadcast mocking needed — pure model logic.

| Test | Asserts |
|------|---------|
| `points_for_rank returns 1 for vote_once regardless of rank` | `points_for_rank(1)` == 1, `points_for_rank(99)` == 1 |
| `points_for_rank returns ranked points for ranked_top_3` | rank 1→30, 2→20, 3→10 |
| `points_for_rank returns 0 for out-of-range rank` | rank 4→0, rank 100→0 |
| `points_for_rank returns 1 when rank is nil` | Both styles return 1 for nil rank |
| `max_ranks returns 3 for ranked_top_3` | |
| `max_ranks returns 1 for vote_once` | |
| `voting_config returns correct defaults` | Match `VOTING_STYLE_DEFAULTS` hash |
| `ranked_voting? and vote_once? return correct booleans` | |
| `generate_unique_code returns 4-char lowercase code` | |
| `generate_unique_code retries on collision` | Stub `Room.exists?` to return true then false |
| `generate_unique_code raises after max_retries` | Stub `Room.exists?` always true, assert `RuntimeError` |

---

### 2. Vote Model Tests (P0)
**File**: `test/models/vote_test.rb` (modify existing empty file)

Needs isolated data (Room → Game → GamePrompt → Users → Answers → Votes chain). Stub broadcasts in setup to handle `after_commit` callbacks on Answer/Vote.

Follow the isolated setup pattern from `test/jobs/answer_smoothing_job_test.rb`.

| Test | Asserts |
|------|---------|
| `points returns 1 for vote_once room` | vote with rank nil → 1 point |
| `points returns rank-based points for ranked_top_3` | rank 1→30, 2→20, 3→10 |
| `points returns 0 for rank beyond top 3` | rank 4→0 |
| `rank validation allows nil` | valid |
| `rank validation requires positive integer` | 0, -1 invalid; 1 valid |

---

### 3. RoomStatusService Results Tests (P0)
**File**: `test/services/room_status_service_test.rb` (new)

Fully isolated data. Room in `Results` status with game + game_prompt wired up. Stub broadcasts.

| Test | Asserts |
|------|---------|
| `picks answer with most vote points as winner` | winner.won == true, correct answer |
| `handles tie by picking one winner` | exactly 1 answer has won: true |
| `reuses existing winner on subsequent calls` | pre-set winner preserved |
| `creates default "poop" answer when no votes exist` | winner.text == "poop", user == creator |
| `sorts answers by points with winner pinned first` | first element is winner |
| `calculates points correctly for ranked_top_3` | points_by_answer matches expected sums |
| `enqueues AnswerSmoothingJob when smooth_answers enabled` | assert_enqueued_with |

---

### 4. CreditsService Tests (P1)
**File**: `test/services/credits_service_test.rb` (new)

Fully isolated data. Multiple users, answers across 2 game_prompts, votes. Stub broadcasts.

**Podium**:
- `returns top 3 by received vote points` — correct order + points
- `returns fewer than 3 when fewer users have votes` — array size matches
- `returns empty array when no votes`

**Swear words**:
- `returns user with highest profanity count` — correct user + count
- `returns nil when no profanity`

**Characters**:
- `returns user with most total characters` — correct user + count

**Efficiency**:
- `returns user with highest points-per-character ratio` — correct ratio
- `excludes users with zero points` — only point-earners eligible
- `returns nil when no users have points`
- `handles zero-length answer gracefully` — no crash

**Spelling**:
- `counts words not in common_words.txt` — correct count
- `skips short and ALL_CAPS words` — not counted
- `returns nil when no mistakes`

**Slowest player**:
- `returns user with highest avg submission percentile` — controlled created_at timestamps
- `returns 50 percentile for single submission` — avg_percentile == 50
- `returns nil when no answers`

---

### 5. Timer Jobs Tests (P1)
**File**: `test/jobs/AnsweringTimesUpJob_test.rb` (new)

Isolated room in `Answering` status. Stub `GamePhasesService#move_to_voting` via `stub_any_instance`.

| Test | Asserts |
|------|---------|
| `calls move_to_voting when valid` | service method invoked |
| `skips when status is not Answering` | NOT invoked |
| `skips when game_prompt_id mismatches` | NOT invoked |

**File**: `test/jobs/VotingTimesUpJob_test.rb` (new)

Same pattern, room in `Voting` status, stub `move_to_results`.

| Test | Asserts |
|------|---------|
| `calls move_to_results when valid` | service method invoked |
| `skips when status is not Voting` | NOT invoked |
| `skips when game_prompt_id mismatches` | NOT invoked |

---

### 6. AnswerSubmittedJob Tests (P1)
**File**: `test/jobs/AnswerSubmittedJob_test.rb` (new)

Isolated data: room in `Answering`, 2 players, game + game_prompt wired. Stub all `Turbo::StreamsChannel` broadcasts. Stub `GamePhasesService#move_to_voting`.

| Test | Asserts |
|------|---------|
| `returns early when status != Answering` | user.status unchanged |
| `returns early when game_prompt has changed` | user.status unchanged |
| `updates user status to Answered` | user.reload.status == Answered |
| `calls move_to_voting when all players answered` | service method invoked |
| `does not call move_to_voting when not all answered` | NOT invoked |

---

### 7. VoteSubmittedJob Tests (P1)
**File**: `test/jobs/VoteSubmittedJob_test.rb` (new)

Same isolated data pattern, room in `Voting`. Test both `vote_once` and `ranked_top_3` paths.

| Test | Asserts |
|------|---------|
| `returns early when status != Voting` | user.status unchanged |
| `returns early when game_prompt changed` | user.status unchanged |
| `updates user status to Voted (vote_once)` | user.reload.status == Voted |
| `calls move_to_results when all voted` | service method invoked |
| `does not mark Voted until all ranks submitted (ranked)` | status NOT Voted after partial ranks |
| `does not call move_to_results when not all voted` | NOT invoked |

---

## Key Patterns to Reuse

**Isolated data setup** (from `test/jobs/answer_smoothing_job_test.rb`):
```ruby
suffix = SecureRandom.hex(4)
@room = Room.create!(code: "tst#{suffix}", ...)
```

**Broadcast stubbing** (from `test/services/game_phases_service_test.rb`):
```ruby
Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
```

**Service stubbing** (from `test/jobs/answer_smoothing_job_test.rb`):
```ruby
GamePhasesService.stub_any_instance(:move_to_voting, nil) { ... }
```

---

## Files Summary

| File | Action | Priority | ~Tests |
|------|--------|----------|--------|
| `test/models/room_test.rb` | Modify | P0 | 11 |
| `test/models/vote_test.rb` | Modify | P0 | 5 |
| `test/services/room_status_service_test.rb` | New | P0 | 7 |
| `test/services/credits_service_test.rb` | New | P1 | 16 |
| `test/jobs/AnsweringTimesUpJob_test.rb` | New | P1 | 3 |
| `test/jobs/VotingTimesUpJob_test.rb` | New | P1 | 3 |
| `test/jobs/AnswerSubmittedJob_test.rb` | New | P1 | 5 |
| `test/jobs/VoteSubmittedJob_test.rb` | New | P1 | 6 |

## Verification

Run after each file is written:
```bash
bin/rails test test/models/room_test.rb
bin/rails test test/models/vote_test.rb
bin/rails test test/services/room_status_service_test.rb
bin/rails test test/services/credits_service_test.rb
bin/rails test test/jobs/AnsweringTimesUpJob_test.rb test/jobs/VotingTimesUpJob_test.rb
bin/rails test test/jobs/AnswerSubmittedJob_test.rb test/jobs/VoteSubmittedJob_test.rb
```

Full suite at the end:
```bash
bin/rails test
```
