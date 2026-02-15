# QA Testing Plan: Audiences Feature

## Prerequisites
- App running at `http://localhost:3000` (`bin/dev`)
- Database seeded with stories
- Playwright MCP enabled for all agents

## Team Roles

| Agent | Game Role | Browser | Responsibility |
|-------|-----------|---------|---------------|
| **Lead (orchestrator)** | Creator | Browser 1 | Room status page, game progression, bug collection |
| **player-1** | Navigator | Browser 2 | First to join, answers, votes, advances rounds |
| **player-2** | Player | Browser 3 | Answers, votes |
| **audience-1** | Audience | Browser 4 | Joins as audience, watches, votes with stars |
| **bug-fixer** | — | No browser | Fixes small bugs in real-time during QA |

---

## Phase 0: Setup
1. Start the server with `bin/dev`
2. Each agent opens a fresh browser to `http://localhost:3000`

## Phase 1: Room Creation & Join Flow

| Step | Agent | Action | Verify |
|------|-------|--------|--------|
| 1.1 | Lead | Navigate to `/rooms/create`, click "Start a Game" | See "C'MON, GET IN HERE!", room code visible |
| 1.2 | Lead | Note the room code, share with team | — |
| 1.3 | player-1 | Navigate to `/session/new`, enter name "Player1" + room code, click "Join Game" | See "Welcome, Player1!", avatar picker visible |
| 1.4 | Lead | Check room status page | Player1 appears in player grid |
| 1.5 | player-2 | Navigate to `/session/new`, enter name "Player2" + room code, click "Join Game" | See "Welcome, Player2!", avatar picker visible |
| 1.6 | Lead | Check room status page | Player2 appears in player grid |
| 1.7 | audience-1 | Navigate to `/session/new`, enter name "Watcher1" + room code, click **"Join as Audience"** | See audience waiting view (no avatar picker, 👁️ avatar, "You're watching" messaging) |
| 1.8 | Lead | Check room status page | Audience count indicator visible (e.g., "1 watching"), audience NOT in player grid |

### Phase 1 Bug Checks
- [ ] "Join as Audience" button exists and is clickable
- [ ] Audience member does NOT appear in the player grid
- [ ] Audience member sees simplified waiting room (no avatar picker)
- [ ] Room capacity is not affected by audience joining

---

## Phase 2: Story Selection & Game Start

| Step | Agent | Action | Verify |
|------|-------|--------|--------|
| 2.1 | Lead | Click "Let's Go!" on status page | See "PICK A STORY" |
| 2.2 | Lead | Select a story (use shortest — "Short Excerpt", 6 blanks), select "Vote Once", click "Start Game" | See "Answer the prompt on your device" |
| 2.3 | player-1 | Wait for auto-navigation | Sees prompt description and answer textarea |
| 2.4 | player-2 | Wait for auto-navigation | Sees prompt description and answer textarea |
| 2.5 | audience-1 | Wait for auto-navigation | Redirected to **waiting page** (NOT answer page). NO answer form, NO "Change Answer" button |

### Phase 2 Bug Checks
- [ ] Audience is redirected to waiting page during answering phase
- [ ] Audience does NOT see answer form
- [ ] Audience does NOT see "Change Answer" button
- [ ] Players see the normal answer form

---

## Phase 3: Answering (Prompt 1)

| Step | Agent | Action | Verify |
|------|-------|--------|--------|
| 3.1 | player-1 | Fill in answer ("magnificent"), click "Submit Answer" | See "Answer submitted" or waiting page |
| 3.2 | player-2 | Fill in answer ("ridiculous"), click "Submit Answer" | Auto-transition to voting |
| 3.3 | audience-1 | Observe | Should auto-navigate to **audience voting UI** when voting phase starts |
| 3.4 | Lead | Check status page | See "Vote for the best answer", both answers listed |

### Phase 3 Bug Checks
- [ ] Audience auto-navigates to voting when all players have answered
- [ ] Audience cannot submit answers (even if navigating to answer URL directly)

---

## Phase 4: Voting (Prompt 1) — THE KEY TEST

| Step | Agent | Action | Verify |
|------|-------|--------|--------|
| 4.1 | player-1 | See voting page with player-2's answer, select it, click "Submit Vote" | Vote submitted |
| 4.2 | player-2 | See voting page with player-1's answer, select it, click "Submit Vote" | Vote submitted, auto-transition to results |
| 4.3 | audience-1 | See **audience star voting UI** | All answers visible (both players'), star +/- buttons, "5 stars remaining" counter, submit button |
| 4.4 | audience-1 | Give 3 stars to first answer, 2 stars to second | Remaining counter shows 0, submit button enabled |
| 4.5 | audience-1 | Click submit | Stars submitted |

### Phase 4 Bug Checks
- [ ] Audience sees ALL answers (not filtered like players)
- [ ] Star increment/decrement buttons work
- [ ] Remaining stars counter updates correctly
- [ ] Cannot exceed 5 total stars
- [ ] Cannot go below 0 stars on any answer
- [ ] Submit button works
- [ ] Audience vote does NOT affect auto-advance timing (players trigger transition)
- [ ] Audience vote does NOT count toward player winner

---

## Phase 5: Results (Prompt 1)

| Step | Agent | Action | Verify |
|------|-------|--------|--------|
| 5.1 | Lead | Check room status results page | Winner shown with trophy. Audience favorite shown with star indicator and count. |
| 5.2 | player-1 | See results page | "Round Complete!", "Next Round" button visible (Navigator) |
| 5.3 | player-2 | See results page | "Round Complete!", no advance button |
| 5.4 | audience-1 | See results page | Results visible |
| 5.5 | Lead | Verify star counts on status page | Answer with most audience stars has star indicator |

### Phase 5 Bug Checks
- [ ] Audience favorite star indicator appears on status page
- [ ] Star count is correct (matches what audience-1 submitted)
- [ ] Player winner (trophy) is based on PLAYER votes only, NOT audience stars
- [ ] If audience gave more stars to the losing answer, trophy and star go to different answers

---

## Phase 6: Subsequent Prompts (Prompts 2+)

| Step | Agent | Action | Verify |
|------|-------|--------|--------|
| 6.1 | player-1 | Click "Next Round" | Advances to next prompt |
| 6.2+ | All | Repeat Phases 3-5 for remaining prompts | Same behavior each round |

### Audience Star Voting Test Cases Per Round
- **Round 1**: 3 stars to first answer, 2 to second (normal distribution)
- **Round 2**: All 5 stars to a single answer (max to one)
- **Round 3**: 1 star to one answer only (partial allocation)
- **Round 4+**: Try edge cases (attempt to exceed 5, attempt to go negative, submit with 0 stars)

---

## Phase 7: Final Results

| Step | Agent | Action | Verify |
|------|-------|--------|--------|
| 7.1 | player-1 | After last prompt results, click "Next Round" | See "Game Complete!" |
| 7.2 | Lead | Check status page | Full story displayed with all winning answers filled in |

---

## Phase 8: Credits

| Step | Agent | Action | Verify |
|------|-------|--------|--------|
| 8.1 | Lead | Navigate to credits (click credits button) | Credits page with podium and superlatives |
| 8.2 | Lead | Check for "Audience Favorite" card | New superlative card visible showing the player who received the most total audience stars |

### Phase 8 Bug Checks
- [ ] "Audience Favorite" superlative card appears
- [ ] Correct player shown (most total audience stars across all prompts)
- [ ] Podium is based on PLAYER votes only (audience stars don't affect it)
- [ ] Star count total is accurate

---

## Phase 9: Edge Case — New Game Without Audience

| Step | Agent | Action | Verify |
|------|-------|--------|--------|
| 9.1 | player-1 | Click "Start New Game" | Back to waiting room |
| 9.2 | Lead | Start a new game WITHOUT audience-1 re-joining | Game works normally |
| 9.3 | Lead | Check results page | No star indicators (no audience) |
| 9.4 | Lead | Check credits page | No "Audience Favorite" card (no audience) |

---

## Game-Breaking Bug Criteria (STOP QA immediately)
- Server error / 500 page
- Player or audience stuck and unable to proceed (infinite loading, broken navigation)
- Game phase won't advance (answering/voting/results stuck)
- ActionCable disconnection that prevents real-time updates
- Audience votes corrupt player vote results (winner changed by audience)

## Bug Report Format
```
BUG-[number]: [short description]
Phase: [which phase]
Agent: [which agent encountered it]
Severity: game-breaking / major / minor / cosmetic
Steps: [what happened]
Expected: [what should happen]
Actual: [what actually happened]
Fix: [small — fixed during QA / deferred — post-QA]
```

## Bug Log

| # | Description | Severity | Phase | Fix |
|---|-------------|----------|-------|-----|
| | | | | |
