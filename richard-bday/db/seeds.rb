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
  "The correct number of beers to drink on a bachelor trip. (Number)",
  "A reasonable number of pairs of underwear to bring on a 3 day trip. (Number)",
  "Describe the temperament of an ideal racing horse. (Phrase)",
  "How would you describe the personality of cats to someone who didn't know what they are. (Phrase)",
  "Most normal activity for a senile elder. (Verb)",
  "Best way to calm a wild animal. (Verb)",
  "The latest new attraction coming to your nearest playground that's got everyone talking. (Phrase; Begin with verb)",
  "Profession (Noun)",
  "Something the prior profession is known for (Phrase; being with verb)",
  "Taboo topics in Dungeon & Dragons (Verb or Noun)",
  "How Richard gets kicked out of the next dinner party (Phrase; begin with verb)",
  "The puzzle that gets Richard banned from /r/puzzles (Noun phrase)",
  "Historical figure most likely to be in heaven (Noun)",
  "Cosmo's secret 13th way to REALLY please your partner (Verb phrase; Verb ending in -ing)",
  "The place with the worst public bathrooms (Place)",
  "Best way to get thrown out of an Applebee's (Verb phrase)",
  "How Paula's mother unexpectedly saves the day at Paula and Richard's wedding (Verb phrase)",
  "How many times Paula has hit Richard. (Number)",
  "The correct number of cats for a house. (Number)"
].map do |name|
  Prompt.find_or_create_by!(description: name)
end

r = Room.find_or_create_by!(code: "36485blahblahblah")
r.update!(status: RoomStatus::WaitingRoom, current_prompt_index: 0)
User.find_or_create_by!(name: "Admin", room: r)

r = Room.find_or_create_by!(code: "bday")
r.update!(status: RoomStatus::WaitingRoom, current_prompt_index: 0)
zach = User.find_or_create_by!(name: "Zach", room: r)
richard = User.find_or_create_by!(name: "Richard", room: r)

p = prompts.first
zachs_answer = Answer.find_or_create_by!(prompt: p, room: r, user: zach, text: "fishy")
richards_answer = Answer.find_or_create_by!(prompt: p, room: r, user: richard, text: "gross")

Vote.find_or_create_by!(user: zach, answer: zachs_answer, prompt: p, room: r)
Vote.find_or_create_by!(user: richard, answer: richards_answer, prompt: p, room: r)
