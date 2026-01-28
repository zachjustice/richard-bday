# User Avatar Feature Implementation Plan

## Summary
Add emoji avatar selection to the waiting page. Avatars display alongside usernames throughout the game. On the results page, voter pills show avatar only. Inactive players' avatars are greyed out (not available) for other users.

---

## Step 1: Database Migration

**New file:** `db/migrate/XXXXXX_add_avatar_to_users.rb`

- Add `avatar` string column to `users` table, **not null** (no default — assigned in model callback)
- Add unique index on `(room_id, avatar)` — unconditional, applies to all users in the room

---

## Step 2: Model Changes

**Modify:** `app/models/user.rb`

- Add `AVATARS` constant — curated list of ~30 animal emojis for players:
  ```
  🦊 🐸 🦄 🐙 🦖 🐝 🦋 🐧 🦀 🐳
  🦩 🐨 🦎 🐲 🦈 🐼 🦉 🐒 🦜 🐬
  🦁 🐢 🐿️ 🦚 🐊 🐴 🦂 🐋 🐺 🦥
  ```
- Add `CREATOR_AVATAR = "🍆"` constant
- Add validation: avatar presence, inclusion in `AVATARS + [CREATOR_AVATAR]`, uniqueness scoped to `room_id`
- Add `before_validation` callback (on create):
  - If `player?`: assign random available avatar from `AVATARS`
  - If `creator?`: assign `CREATOR_AVATAR`
- Add `self.available_avatars(room_id)` class method — returns `AVATARS` minus all avatars taken in this room (including inactive players, so inactive avatars show as greyed out)
- Add `avatar_with_name` helper → `"🦊 PlayerName"`

---

## Step 3: Routes

**Modify:** `config/routes.rb`

Add one route:
```ruby
patch "/avatar", to: "avatars#update", as: :update_avatar
```

No shuffle route — shuffle logic handled client-side via Stimulus controller.

---

## Step 4: Avatar Controller

**New file:** `app/controllers/avatars_controller.rb`

- `update` action: validate emoji is in AVATARS, set on current_user, save. On success: broadcast update to room status page + respond with Turbo Stream replacing avatar display and picker. On failure (taken): respond with Turbo Stream showing error message.
- `broadcast_avatar_update` private method: `Turbo::StreamsChannel.broadcast_replace_to` targeting the user's `_user_list_item` on the room status page via `rooms:#{room.id}:users` channel.

Race condition safety: DB unique index is the ultimate guard. Validation failure → show "That avatar is already taken!" error.

---

## Step 5: Avatar Picker UI (Player Waiting Page)

**Modify:** `app/views/rooms/show.html.erb`
- Replace static `☺️` with user's current avatar (no animation)
- Add avatar picker section below welcome heading (no heading text on the picker)

**New file:** `app/views/avatars/_current_avatar.html.erb`
- Shows user's avatar large, wrapped in `#avatar-display` div for Turbo targeting. No animations.

**New file:** `app/views/avatars/_picker.html.erb`
- Shuffle button (calls Stimulus controller to randomly select an available emoji client-side and submit)
- Error message display area (shown when race condition occurs)
- 6-column grid (5 on mobile) of all AVATARS:
  - **Taken (including inactive players):** grayed out, `opacity-30 grayscale cursor-not-allowed`
  - **Current:** highlighted border
  - **Available:** clickable, each wrapped in a small `PATCH` form to `update_avatar_path`

**New file:** `app/javascript/controllers/avatar_shuffle_controller.js`
- Stimulus controller that reads available avatars from data attributes
- On "shuffle" click: randomly picks one of the available emoji forms and submits it

---

## Step 6: Update Existing Views

### a) `app/views/rooms/partials/_user_list_item.html.erb`
- Change `user.name` → `user.avatar_with_name` (waiting room TV display)

### b) `app/views/rooms/partials/_user_with_status_item.html.erb`
- Change `user.name` → `user.avatar_with_name` (answering/voting status on TV)

### c) `app/views/rooms/status/_results.html.erb`
- Answer author (line 18): `answer.user.name` → `answer.user.avatar_with_name`
- Voter pills — ranked (line 35): `vote.user.name` → `vote.user.avatar`
- Voter pills — vote_once (line 43): `vote.user.name` → `vote.user.avatar`

### d) `app/views/rooms/status/_final_results.html.erb`
- "Written by" pills (line 16): `user.name` → `user.avatar_with_name`
- Export version (line 67): `user.name` → `user.avatar_with_name`

### e) `app/views/rooms/show.html.erb`
- Remove `animate-swing` class from the existing emoji div

---

## Step 7: No Changes Needed (Automatic)

These files render user partials via Turbo Stream broadcasts — they pick up avatar changes automatically:
- `app/jobs/JoinRoomJob.rb` — renders `_user_list_item` (now includes avatar)
- `app/jobs/AnswerSubmittedJob.rb` — renders `_user_with_status_item` (now includes avatar)
- `app/jobs/VoteSubmittedJob.rb` — renders `_user_with_status_item` (now includes avatar)
- `app/controllers/sessions_controller.rb` — `User.new` triggers `before_validation` callback for avatar assignment

---

## Files to Create
| File | Purpose |
|------|---------|
| `db/migrate/XXXXXX_add_avatar_to_users.rb` | Migration |
| `app/controllers/avatars_controller.rb` | Avatar update endpoint |
| `app/views/avatars/_current_avatar.html.erb` | Current avatar display partial |
| `app/views/avatars/_picker.html.erb` | Emoji grid picker partial |
| `app/javascript/controllers/avatar_shuffle_controller.js` | Client-side shuffle logic |

## Files to Modify
| File | Change |
|------|--------|
| `app/models/user.rb` | AVATARS constant, validations, callbacks, helpers |
| `config/routes.rb` | One new route |
| `app/views/rooms/show.html.erb` | Add avatar picker, remove animations |
| `app/views/rooms/partials/_user_list_item.html.erb` | `avatar_with_name` |
| `app/views/rooms/partials/_user_with_status_item.html.erb` | `avatar_with_name` |
| `app/views/rooms/status/_results.html.erb` | `avatar_with_name` / `user.avatar` |
| `app/views/rooms/status/_final_results.html.erb` | `avatar_with_name` |

---

## Verification

1. **Run migration:** `bin/rails db:migrate`
2. **Run existing tests:** `bin/rails test` — ensure nothing breaks
3. **Manual testing flow:**
   - Create a room, join with 2+ browser tabs
   - Verify random avatar assigned on join
   - Verify avatar + name shows on room status TV page
   - Pick a new avatar — verify it updates on TV page in real-time
   - Try picking a taken avatar — verify error message
   - Click shuffle — verify new random avatar assigned (client-side pick + server save)
   - Have a player leave (inactive) — verify their avatar is greyed out for others
   - Start game, submit answers — verify avatar + name on answering status
   - Vote — verify avatar + name on voting status
   - View results — verify avatar-only on voter pills, avatar + name on answer author
   - View final story — verify avatar + name on "Written by" pills
   - Verify Creator user gets 🍆 avatar automatically
4. **Run system tests:** `bin/rails test test/system/`
