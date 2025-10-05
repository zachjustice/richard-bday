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

s = Story.find_or_create_by!(original_text: "I loved my pet dog. My favorite think about her was that she was fluffy. But when she died after many years, my husband said \"I don't like dogs.\"", text: "todo")

blanks = [
  [ "animal", "noun" ],
  [ "drink", "adjective" ],
  [ "phrase" ]
].map do |tags|
  Blank.find_or_create_by!(story: s, tags: tags.join)
end

s.update(text: "I loved my pet {#{blanks[0].id}}." + \
 " My favorite thing about her was that she was {#{blanks[1].id}}." + \
 " But when she died after many years, my husband said \"{#{blanks[2].id}}\"."
)

r = Room.find_or_create_by!(code: "36485blahblahblah")
r.update!(status: RoomStatus::WaitingRoom, current_prompt_index: 0)
User.find_or_create_by!(name: "Admin", room: r)

g = Game.find_or_create_by(story: s, room: r)

prompts.zip(blanks).map do |p, b|
  GamePrompt.find_or_create_by!(prompt: p, blank: b, game: g)
end

r = Room.find_or_create_by!(code: "bday")
r.update!(status: RoomStatus::WaitingRoom, current_prompt_index: 0)
zach = User.find_or_create_by!(name: "Zach", room: r)
richard = User.find_or_create_by!(name: "Richard", room: r)

p = prompts.first
zachs_answer = Answer.find_or_create_by!(prompt: p, room: r, user: zach, text: "fishy")
richards_answer = Answer.find_or_create_by!(prompt: p, room: r, user: richard, text: "gross")

Vote.find_or_create_by!(user: zach, answer: zachs_answer, prompt: p, room: r)
Vote.find_or_create_by!(user: richard, answer: richards_answer, prompt: p, room: r)
