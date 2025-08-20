# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
r = Room.find_or_create_by!(code: "bday")
zach = User.new(name: "Zach", room_id: r.id).save
richard = User.new(name: "Richard", room_id: r.id).save

p = Prompt.new(description: "What is an ADJECTIVE for something smelly?").save

zachs_answer = Answer.new(prompt_id: p.id, room_id: r.id, user_id: zach.id, text: "fishy")
richards_answer = Answer.new(prompt_id: p.id, room_id: r.id, user_id: richard.id, text: "gross")

Vote.new(user_id: zach.id, answer_id: zachs_answer, prompt_id: p.id, room_id: r.id)
Vote.new(user_id: richard.id, answer_id: richards_answer, prompt_id: p.id, room_id: r.id)
