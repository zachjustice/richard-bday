# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
prompts = [
  [ "What is the sexiest animal?", [ "animal", "noun" ] ],
  [ "What is the worst adjective for a cup of coffee?", [ "drink", "adjective" ] ],
  [ "What is the worst thing to say to a child that is sad their fish died?", [ "phrase" ] ]
].map do |name, tags|
  Prompt.find_or_create_by!(description: name, tags: tags.join(","))
end

[
  [ "A Ship in the Night", "TODO1", "TODO1" ],
  [ "Death Becomes Her", "TODO2", "TODO2" ]
].each do |title, original_text, text|
  Story.find_or_create_by!(title:, original_text:, text:)
end

original_story = "I loved my pet dog. My favorite think about her was that she was fluffy. But when she died after many years, my husband said \"I don't like dogs.\""
s = Story.find_by(original_text: original_story)
if s.nil?
  s = Story.create(title: "My Dog", original_text: original_story, text: "todo")
end

blanks = [
  [ "animal", "noun" ],
  [ "drink", "adjective" ],
  [ "phrase" ]
].map do |tags|
  Blank.find_or_create_by!(story: s, tags: tags.join(","))
end

s.update(text: "I loved my pet {#{blanks[0].id}}." + \
 " My favorite thing about her was that she was {#{blanks[1].id}}." + \
 " But when she died after many years, my husband said \"{#{blanks[2].id}}\"."
)

# Support the hacky solution for room creation where we start a user session for the first user in the DB.
r = Room.find_or_create_by!(code: "36485blahblahblah")
r.update!(status: RoomStatus::WaitingRoom)
User.find_or_create_by!(name: "Admin", room: r)



g = Game.find_or_create_by(story: s, room: r)

order = 0
game_prompts = prompts.zip(blanks).map do |p, b|
  gp = GamePrompt.find_or_create_by!(prompt: p, blank: b, game: g, order: order)
  order += 1
  gp
end
g.update!(current_game_prompt_id: game_prompts.first.id)


r = Room.find_or_create_by!(code: "bday")
r.update!(status: RoomStatus::WaitingRoom, current_game_id: g.id)
zach = User.find_or_create_by!(name: "Zach", room: r)
richard = User.find_or_create_by!(name: "Richard", room: r)

game_prompt = game_prompts.first
zachs_answer = Answer.find_or_create_by!(game_prompt: game_prompt, game: g, user: zach, text: "fishy")
richards_answer = Answer.find_or_create_by!(game_prompt: game_prompt, game: g, user: richard, text: "gross")

Vote.find_or_create_by!(user: zach, answer: zachs_answer, game: g, game_prompt: game_prompt)
Vote.find_or_create_by!(user: richard, answer: richards_answer, game: g, game_prompt: game_prompt)
