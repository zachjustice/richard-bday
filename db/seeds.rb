# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
def seed_example_data
  prompts = [
    [ "What is the sexiest animal?", [ "animal", "noun" ] ],
    [ "What is the worst adjective for a cup of coffee?", [ "drink", "adjective" ] ],
    [ "What is the worst thing to say to a child that is sad their fish died?", [ "phrase" ] ]
  ].map do |name, tags|
    Prompt.find_or_create_by!(description: name, tags: tags.join(","))
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
end


def create_story(story_parts)
  s = Story.find_by(original_text: story_parts[:original_text])
  if s.nil?
    s = Story.create!(title: story_parts[:title], original_text: story_parts[:original_text], text: "todo")
  end

  blanks = story_parts[:prompts].map { |prompt_and_tags|
    prompt = prompt_and_tags[0]
    tags_str = prompt_and_tags[1].join(",")
    Prompt.find_or_create_by!(
      description: prompt,
      tags: tags_str
    )
    Blank.find_or_create_by!(
      story: s,
      tags: tags_str
    )
  }

  templated_story = story_parts[:text]
  while templated_story.include?("{}") do
    templated_story.sub!("{}", "{#{blanks.shift.id}}")
  end

  s.update!(text: templated_story)
end


stories =  [ {
  title: "Essay on World History",
  original_text: "The history of all hitherto existing society is the history of class struggles.  In the earlier epochs of history we find almost everywhere a complicated arrangement of society into various orders, a manifold gradation of social rank. In ancient Rome we have patricians, knights, plebeians, slaves; in the middle ages, feudal lords, vassals, guild masters, journeymen, apprentices, serfs; in almost all of these classes, again, subordinate gradations.  The modern bourgeois society that has sprouted from the ruins of feudal society, has not done away with class antagonisms. It has but established new classes, new conditions of oppression, new forms of struggle in place of the old ones. Our epoch, the epoch of the bourgeois, possesses, however, this distinctive feature: it has simplified the class antagonisms. Society as a whole is more and more splitting up into two great hostile camps, into two great classes directly facing each other: Bourgeoisie and Proletariat.",
  text: "The history of all hitherto existing society is the history of {}.  In the earlier epochs of history we find almost everywhere a complicated arrangement of society into various orders, a manifold gradation of social rank. In ancient {} patricians, knights, plebeians, {}; in the middle ages, feudal lords, vassals, guild masters, journeymen, apprentices, {}; in almost all of these classes, again, subordinate gradations. The {} bourgeois society that has sprouted from the ruins of feudal society, has not done away with {}.  It has but established {}, new conditions of oppression, new forms of struggle in place of the old ones.  Our epoch, the epoch of {}, possesses, however, this distinctive feature: it has simplified {}. Society as a whole is more and more splitting up into two great hostile camps, into two great classes directly facing each other: {} and {}.",
  prompts: [
    [
      "The most vexing part of the King of England's day.",
      [ "phrase", "something_vexing" ]
    ],
    [
      "Wrong answer for an ancient culture on your high school history quiz.",
      [ "noun", "ancient_culture" ]
    ],
    [
      "The worst job to have in ancient rome.",
      [ "noun", "job" ]
    ],
    [
      "The worst person to run into at a party.",
      [ "noun", "type_of_person" ]
    ],
    [
      "Adjective your grand uncle uses for a pride parade.",
      [ "adjective", "pride_parade" ]
    ],
    [
      "What a five year old thinks is the worst part of having a day job.",
      [ "phrase", "job" ]
    ],
    [
      "A new form of bullying invented by cruel tweens.",
      [ "phrase", "bullying" ]
    ],
    [
      "Suprsingly, this activity is most likely to make everyone hate you.",
      [ "noun", "activity" ]
    ],
    [
      "The most complicated thing about being a toddler",
      [ "noun", "complicated" ]
    ],
    [
      "You want to be the next best-selling author for young adults. What CATCHY NICKNAME do you use for the evil organization that controls the world?",
        [ "noun", "bad_guys" ]
    ],
    [
      "You want to be the next best-selling author for young adults. What CATCHY NICKNAME do you use for the scrappy band of rebels that's going to save the world",
        [ "noun", "good_guys" ]
    ]
  ]
}
]

seed_example_data
stories.each { |s| create_story(s) }
