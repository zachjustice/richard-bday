# Game Flow - Happy Path Documentation

## Overview
This is a multiplayer Mad Libs-style game where players fill in blanks in a story, vote on the best answers, and see a completed story at the end.

## Complete Player Journey

### 1. Landing Page / Room Creation
- **URL**: `/` (root)
- **Action**: User visits the landing page
- **Page Content**: Shows waiting room with users list
- **Room Status**: `WaitingRoom`
- **User State**: Not authenticated

### 2. Player Registration
- **Action**: User registers with a name and room code
- **API Call**: `POST /session/new`
- **Request Body**:
  ```json
  {
    "user": {
      "name": "PlayerName",
      "room": "room_id"
    }
  }
  ```
- **Response**: User receives encrypted session token
- **Result**: User is added to the room and authenticated
- **Session Created**: User session is established

### 3. Waiting Room
- **URL**: `/rooms/:id/status`
- **Action**: Players wait for game host to start the game
- **Page Content**:
  - List of all users in the room
  - Story selection dropdown (for host)
  - "Start Game" button (for host)
  - Real-time updates via ActionCable as players join
- **Room Status**: `WaitingRoom`
- **Minimum Players**: Typically 2+ players for best experience

### 4. Game Start
- **Action**: Host selects a story and clicks "Start Game"
- **API Call**: `POST /rooms/:id/start`
- **Request Params**: `{ story: story_id }`
- **Backend Process**:
  1. Creates a new `Game` record for the room
  2. Creates `GamePrompt` records from story blanks
     - Prompts are matched to blanks by tags
     - GamePrompts are ordered sequentially (0, 1, 2, ...)
  3. Sets `game.current_game_prompt_id` to first prompt
  4. Sets room status to `Answering`
  5. Sets `room.current_game_id` to new game
  6. Broadcasts "NextPrompt" event via ActionCable to all connected clients
- **Result**: All players are redirected to the first prompt
- **Room Status**: `Answering`

### 5. Answering Phase (Repeated for each prompt)
- **URL**: `/prompts/:id` (show action)
- **Page Content**:
  - Prompt description (e.g., "What is the sexiest animal?")
  - Prompt tags displayed (e.g., "animal, noun")
  - Text input field for answer
  - Submit button
- **Action**: Player types their answer and clicks submit
- **API Call**: `POST /answer`
- **Request Params**: `{ text: "answer text", prompt_id: prompt_id }`
- **Backend Validation**:
  - Answer is idempotent (duplicate submissions ignored)
  - One answer per user per prompt per game
- **Room Status**: `Answering`

### 6. Waiting for Other Players
- **URL**: `/prompts/:id/waiting`
- **Page Content**:
  - Message: "Waiting for other players to submit answers..."
  - List of users who have submitted answers
  - Real-time updates via ActionCable
  - Progress indicator
- **Backend Logic**:
  - When `submitted_answers >= users_in_room`
  - Room status changes to `Voting`
  - ActionCable broadcasts status change
- **Transition**: Players are auto-redirected to voting page
- **Room Status**: Transitions from `Answering` to `Voting`

### 7. Voting Phase
- **URL**: `/prompts/:id/voting`
- **Page Content**:
  - Prompt description shown again
  - List of all answers from other players
  - **Important**: User's own answer is NOT shown
  - Vote button for each answer
- **Action**: Player clicks vote button for their favorite answer
- **API Call**: `POST /vote`
- **Request Params**: `{ answer_id: answer_id, game_prompt_id: prompt_id }`
- **Backend Validation**:
  - Vote is idempotent (duplicate votes ignored)
  - One vote per user per prompt
- **Room Status**: `Voting`
- **Result**: Player is redirected to results page

### 8. Waiting for Votes
- **URL**: `/prompts/:id/results` (before all votes submitted)
- **Page Content**:
  - Message: "Waiting for all votes..."
  - May show partial vote counts as they come in
  - Real-time updates via ActionCable
- **Backend Logic**:
  - When `submitted_votes >= users_in_room`
  - Room status changes to `Results`
  - Winners are calculated
- **Room Status**: Transitions from `Voting` to `Results`

### 9. Round Results
- **URL**: `/prompts/:id/results` (after all votes)
- **Page Content**:
  - All answers displayed with vote counts
  - Winning answer(s) highlighted
  - "Next Round" or "Next Prompt" button (for host)
- **Backend Process**:
  - Calculates votes per answer
  - Determines winner (most votes)
  - Marks winning answer with `won: true` in database
  - In case of tie, randomly selects one winner
- **Room Status**: `Results`
- **Action**: Host clicks "Next" to advance to next prompt

### 10. Next Prompt
- **Action**: Host clicks "Next" button
- **API Call**: `POST /rooms/:id/next`
- **Backend Process**:
  1. Finds next GamePrompt (current order + 1)
  2. If next prompt exists:
     - Updates `game.current_game_prompt_id`
     - Sets room status to `Answering`
     - Broadcasts "NextPrompt" event via ActionCable
     - **Returns to Step 5** (Answering Phase)
  3. If no next prompt exists:
     - Sets room status to `FinalResults`
     - Proceeds to Final Results
- **Result**: Cycle repeats from step 5 for each prompt in the story

### 11. Final Results
- **URL**: `/rooms/:id/status`
- **Trigger**: Host clicks "Next" after the last prompt results
- **Page Content**:
  - Complete story with blanks filled in by winning answers
  - Story displayed sentence by sentence
  - Story title shown at top
  - "End Game" button to return to waiting room
- **Room Status**: `FinalResults`
- **Backend Process**:
  1. Retrieves story template text
  2. Finds all winning answers for the game
  3. Replaces `{blank_id}` placeholders with winning answer text
  4. Validates all blanks are filled (logs errors if not)
  5. Splits story into sentences for display

### 12. Game End
- **Action**: Host clicks "End Game" button
- **API Call**: `POST /rooms/:id/end_game`
- **Backend Process**:
  1. Clears `game.current_game_prompt_id` (sets to nil)
  2. Sets room status to `WaitingRoom`
  3. Clears `room.current_game_id` (sets to nil)
- **Result**:
  - Returns to waiting room
  - Players can start a new game with a different story
  - Game history is preserved in database
- **Room Status**: `WaitingRoom`

## Data Model Overview

### Key Models
- **Room**: Container for players, tracks game status
- **User**: Player in a room, has name and session
- **Story**: Template with title, original text, and blanks
- **Blank**: Placeholder in story with tags (e.g., "animal, noun")
- **Prompt**: Question to ask players, matched to blanks by tags
- **Game**: Instance of a story being played in a room
- **GamePrompt**: Specific prompt for a game, linked to blank, ordered sequentially
- **Answer**: Player's response to a prompt, marked `won: true` if it wins
- **Vote**: Player's vote on an answer

### Room Status Flow
```
WaitingRoom
  ↓ (game starts)
Answering
  ↓ (all answers submitted)
Voting
  ↓ (all votes submitted)
Results
  ↓ (host clicks next)
Answering (next prompt)
  ... (repeat for each prompt)
  ↓ (no more prompts)
FinalResults
  ↓ (host ends game)
WaitingRoom
```

## Key Business Rules

1. **Answer Submission**:
   - One answer per user per prompt per game
   - Idempotent (duplicate submissions ignored)
   - Cannot edit after submission

2. **Voting**:
   - One vote per user per prompt
   - Cannot vote for own answer
   - Idempotent (duplicate votes ignored)

3. **Winner Selection**:
   - Answer with most votes wins
   - Ties broken randomly
   - Only one answer marked `won: true` per prompt

4. **Prompt-Blank Matching**:
   - Prompts matched to blanks by tags
   - Both must have identical tag string

5. **Story Completion**:
   - All blanks must have winning answers
   - Blank placeholders use format `{blank_id}`
   - System validates and logs errors if story incomplete

## Real-Time Features (ActionCable)

The application uses ActionCable for real-time updates:

1. **Player Joins**: Broadcast to update user list in waiting room
2. **Game Start**: Broadcast "NextPrompt" event to all players
3. **Answer Submitted**: Update waiting room progress
4. **All Answers In**: Trigger transition to voting
5. **Vote Submitted**: Update results page with vote counts
6. **All Votes In**: Trigger results calculation and display
7. **Next Prompt**: Broadcast to advance all players

## Critical UI Elements for Testing

### Waiting Room (`/rooms/:id/status`)
- User list with player names
- Story dropdown (host only)
- "Start Game" button (host only)

### Answer Prompt (`/prompts/:id`)
- Prompt text/description
- Tags display
- Answer input field
- Submit button

### Waiting Page (`/prompts/:id/waiting`)
- "Waiting..." message
- List of users who submitted

### Voting Page (`/prompts/:id/voting`)
- Prompt description
- List of answers (excluding user's own)
- Vote buttons

### Results Page (`/prompts/:id/results`)
- All answers with vote counts
- Winner highlighted/indicated
- "Next" button (host only)

### Final Results (`/rooms/:id/status` with FinalResults)
- Story title
- Complete story with filled blanks
- "End Game" button (host only)

## Test Assertions Checklist

For a comprehensive E2E test, verify:

1. Users can register and appear in room
2. Host can select story and start game
3. Prompt text and tags are displayed
4. Users can submit answers
5. Waiting page shows submitted users
6. Voting page excludes user's own answer
7. Users can vote on answers
8. Results show vote counts
9. Winner is indicated
10. Host can advance to next prompt
11. Final story displays with all blanks filled
12. Story title is shown
13. Host can end game and return to waiting room
