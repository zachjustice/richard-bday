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
zach = User.find_or_create_by!(name: "Zach", room: r)
richard = User.find_or_create_by!(name: "Richard", room: r)

p = Prompt.find_or_create_by!(description: "What is an ADJECTIVE for something smelly?")

zachs_answer = Answer.find_or_create_by!(prompt: p, room: r, user: zach, text: "fishy")
richards_answer = Answer.find_or_create_by!(prompt: p, room: r, user: richard, text: "gross")

Vote.find_or_create_by!(user: zach, answer: zachs_answer, prompt: p, room: r)
Vote.find_or_create_by!(user: richard, answer: richards_answer, prompt: p, room: r)
