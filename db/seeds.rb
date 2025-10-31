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
  puts("Example data")
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
    puts("Creating story: #{story_parts[:title]}")
    s = Story.create!(title: story_parts[:title], original_text: story_parts[:original_text], text: "todo")
  else
    puts("Updating story: #{story_parts[:title]}")
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
  unmatched_placeholder = templated_story.scan(/\{(\d+)\}/).flatten.sort.last.to_i
  if unmatched_placeholder > blanks.size
    raise "Error persisting story title '#{story_parts[:title]}'. Found problematic placeholder '{#{unmatched_placeholder}}' with #{blanks.size} blanks in story.\n\nSTORY:\n\n  #{templated_story}"
  end

  blanks.each_with_index { |blank, index|
    needle = "{#{index + 1}}"
    if templated_story.include?(needle)
      templated_story.sub!(needle, "{#{blank.id}}")
    else
      raise "Error persisting story title '#{story_parts[:title]}'. Errored on index #{index}. #{blanks.size} blanks in story."
    end
  }
  if templated_story.include?("{}")
    raise "Error persisting story title '#{story_parts[:title]}'. Found empty placeholder. #{blanks.size} blanks in story.\n\nStory:\n\n  #{templated_story}"
  end

  s.update!(text: templated_story)
end


stories =  [
  {
    title: "Essay on World History",
    original_text: "The history of all hitherto existing society is the history of class struggles.\n\nIn the earlier epochs of history we find almost everywhere a complicated arrangement of society into various orders, a manifold gradation of social rank. In ancient Rome we have patricians, knights, plebeians, slaves; in the middle ages, feudal lords, vassals, guild masters, journeymen, apprentices, serfs; in almost all of these classes, again, subordinate gradations.  The modern bourgeois society that has sprouted from the ruins of feudal society, has not done away with class antagonisms. It has but established new classes, new conditions of oppression, new forms of struggle in place of the old ones. Our epoch, the epoch of the bourgeois, possesses, however, this distinctive feature: it has simplified the class antagonisms. Society as a whole is more and more splitting up into two great hostile camps, into two great classes directly facing each other: Bourgeoisie and Proletariat.",
    text: "The history of all hitherto existing society is the history of {1}.\n\nIn the earlier epochs of history we find almost everywhere a complicated arrangement of society into various orders, a manifold gradation of social rank. The ancient people known as the '{2}' had patricians, knights, plebeians, and the famously poor '{3}'. The middle ages had feudal lords, vassals, guild masters, journeymen, apprentices, and {4}. In almost all of these classes, again, subordinate gradations. The {5} bourgeois society that has sprouted from the ruins of feudal society, has not done away with {6}.  It has but established {7}, new conditions of oppression, new forms of struggle in place of the old ones.  Our epoch, the epoch of {8}, possesses, however, this distinctive feature: it has simplified {9}. Society as a whole is more and more splitting up into two great hostile camps, into two great classes directly facing each other: {10} and {11}.",
    prompts: [
      [
        "The most vexing part of the King of England's day.",
        [ "phrase", "something_vexing" ]
      ],
      [
        "A wrong answer for the name of an ancient culture on your high school history quiz.",
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
  },
  {
    title: "Short Excerpt from an Essay on a Shakespearen play",
    original_text: 'In his essay "Preposterous Pleasures: Queer Theories and A Midsummer Night\'s Dream", Douglas E. Green explores possible interpretations of alternative sexuality that they find within the text of Shakespeare\'s "A Midsummer Night\'s Dream", in juxtaposition to the proscribed social mores of the culture at the time the play was written. They write that the essay "does not seek to rewrite it as a gay play but rather lend a critical analysis to overlooked themes of this underappreciated work of Shakespeare\'s. Green does not consider Shakespeare to have been a "sexual radical", but that the play represented a "topsy-turvy world" or "temporary holiday" that mediates or negotiates the "discontents of civilization, which while resolved neatly in the story\'s conclusion, do not resolve so neatly in real life. Green writes that theme of "homoeroticism" in the story must be considered in the context of the "culture of early modern England as a commentary on the "aesthetic rigidities of comic form and political ideologies."',
    text: "In his essay 'Preposterous Pleasures: {1}', {2} explores possible interpretations of alternative sexuality that they find within the text of Shakespeare's '{3}', in juxtaposition to the proscribed social mores of the culture at the time the play was written.\n\nThey write that the essay 'does not seek to rewrite '{3}' as a {4} play but rather lend a critical analysis to overlooked themes of this underappreciated work of Shakespeare's.'\n\n{2} does not consider Shakespeare to have been a 'sexual radical', but that the play represented a 'topsy-turvy world' or 'temporary holiday' that mediates or negotiates the 'discontents of civilization', which while resolved neatly in the story's conclusion, do not resolve so neatly in real life.' They write that the theme of '{5}' in the story must be considered in the context of the 'culture of {6}' as a commentary on the 'aesthetic rigidities of comic form and political ideologies.'",
    prompts: [
      [
        "What is a made-up title of an academic essay about sex that was required reading in your college english class?",
        [ "title", "essay", "sex", "shakespeare_play" ]
      ],
      [
        "What would be the worst possible name for a literary critic or academic author?",
        [ "name", "author", "shakespeare_play" ]
      ],
      [
        "Historians have found a long-lost Shakespearean play. Surprisingly, its named: _____",
        [ "title", "long_lost_shakespearean_play", "shakespeare_play" ]
      ],
      [
        "What is the worst adjective to describe a Radical Movement's Agenda?",
        [ "adjective", "radical_agenda", "shakespeare_play" ]
      ],
      [
        "What theme does your English teacher insist is in this play, but no matter how much you look, you can’t find it?",
        [ "literary_theme", "english_class", "shakespeare_play" ]
      ],
      [
        "What is your neighbor’s most annoying hobby?",
        [ "noun", "activity", "shakespeare_play" ]
      ]
    ]
  },
  {
    title: "A Fable on Gluttony",
    original_text: "A VERY HUNGRY FOX, seeing some bread and meat left by shepherds in the hollow of an oak, crept into the hole and made a hearty meal. When he finished, he was so full that he was not able to get out, and began to groan and lament his fate. Another Fox passing by heard his cries, and coming up, inquired the cause of his complaining. On learning what had happened, he said to him, “Ah, you will have to remain there, my friend, until you become such as you were when you crept in, and then you will easily get out.”",
    text: "A VERY HUNGRY {1}, seeing some {2} and {3} left by {4} in the hollow of an oak, crept into the hole and made a hearty meal. When they finished, she was so full that she was not able to get out, and began to {5} and lament her fate. Another {6} passing by heard their cries, and coming up, inquired the cause of his complaining. On learning what had happened, it said to her, “{7}”",
    prompts: [
      [
        "Your love interest is a 10, but has a pet _____",
        [ "noun", "animal", "aesops_fable" ]
      ],
      [
        "Oh no! The wings you just ate were covered in ghost pepper hot sauce, but the only thing you have to drink is _____",
        [ "noun", "drink", "aesops_fable" ]
      ],
      [
        "Stranded on this snowy mountain, our choices for food are _____ or cannibalism. Guess we're choosing cannibalism.",
        [ "noun", "food", "aesops_fable" ]
      ],
      [
        "Growing up my parents, said I could choose between being a lawyer, doctor, or _____",
        [ "noun", "career", "aesops_fable" ]
      ],
      [
        "What is a verb to describe the sound or reaction you make when you stub your toe?",
        [ "verb", "reaction", "aesops_fable" ]
      ],
      [
        "This year, this mythical beast is the heartthrob of all the teen girl: _____.",
        [ "noun", "animal", "aesops_fable" ]
      ],
      [
        "A phrase you can say to try and sound wise that's actually dumb",
        [ "phrase", "dumb_wise", "aesops_fable" ]
      ]
    ]
  },
  {
    title: "Fast-food Press Release",
    original_text: "People called, and the latest and greatest selling quick-service franchise, {Name a fictional fast-food restaurant.}, is answering. {1}'s beloved {Name a food item this restaurant sells.} are officially back by obsessive demand beginning next at stores nationwide.\n\nFor years, {1} has heard from fans clamoring for a chance to try their famous {What's the BEST adjective to describe this food item?} {2} again, through millions of social media comments and petition signatures.\n\nWhen {1} fired up a surprise drop of {What's the WORST adjective to describe this food item?} {2} in {The city with the worst public bathrooms}, local fans were elated, leading to an early sellout in some restaurants.\n\n{1} first introduced {2} 5 years ago as a menu staple, quickly earning a cult status among fans, before a hotly debated discontinuation last fall that famously lead to one restaurant-goer's arrest after they {How your drunk aunt got arrested in Applebee's.}.\n\n\"{1}-lovers, we heard you—and we agree it's been five long years without {2}. But the wait is over,\" said {The name of the president of this restaurant chain} the President of {1}. \"This isn't just a nostalgic nod. It's an example of how we're turning feedback into action. As we say here at {1}: {Famous catchphrase for this restaurant}\"",
    text: "People called, and the latest and greatest selling quick-service franchise, {1}, is answering. {1}'s beloved {2} are officially back by obsessive demand beginning next at stores nationwide.\n\nFor years, {1} has heard from fans clamoring for a chance to try their famous {3} {2} again, through millions of social media comments and petition signatures.\n\nWhen {1} fired up a surprise drop of {4} {2} in {5}, local fans were elated, leading to an early sellout in some restaurants.\n\n{1} first introduced {2} 5 years ago as a menu staple, quickly earning a cult status among fans, before a hotly debated discontinuation last fall that famously lead to one restaurant-goer's arrest after they {6}.\n\n\"{1}-lovers, we heard you—and we agree it's been five long years without {2}. But the wait is over,\" said {7} the President of {1}. \"This isn't just a nostalgic nod. It's an example of how we're turning feedback into action. As we say here at {1}: '{8}'\"",
    prompts: [
      [
        "Name a fictional fast-food restaurant.",
        [ "noun", "restaurant", "fictional" ]
      ],
      [
        "Name a food item this restaurant sells.",
        [ "noun", "food", "menu_item" ]
      ],
      [
        "What's the BEST adjective to describe this food item?",
        [ "adjective", "food", "positive" ]
      ],
      [
        "What's the WORST adjective to describe this food item?",
        [ "adjective", "food", "negative" ]
      ],
      [
        "The city with the worst public bathrooms",
        [ "noun", "city", "funny" ]
      ],
      [
        "How your drunk aunt got arrested in Applebee's.",
        [ "phrase", "incident", "funny" ]
      ],
      [
        "The name of the president of this restaurant chain",
        [ "name", "person", "president" ]
      ],
      [
        "Famous catchphrase for this restaurant",
        [ "phrase", "slogan", "restaurant" ]
      ]
    ]
  }
]

# Recipe
# Announcement for new restaraunt and / or dairy queen item
# News announcement for local arrest / incident
# Lore about a spooky monster

# seed_example_data
puts("Creating stories")
stories.each { |s| create_story(s) }
