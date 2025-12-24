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
    phrases = prompt_and_tags[:phrases]
    tags_str = prompt_and_tags[:tags].join(",")

    b = Blank.find_or_create_by!(
      story: s,
      tags: tags_str
    )

    phrases.each { |phrase|
      p = Prompt.find_or_create_by!(
        description: phrase,
        tags: tags_str
      )

      StoryPrompt.find_or_create_by!(
        story: s,
        blank: b,
        prompt: p
      )
    }

    b
  }

  templated_story = story_parts[:text]
  unmatched_placeholder = templated_story.scan(/\{(\d+)\}/).flatten.sort.last.to_i
  if unmatched_placeholder > blanks.size
    raise "Error persisting story title '#{story_parts[:title]}'. Found problematic placeholder '{#{unmatched_placeholder}}' with #{blanks.size} blanks in story.\n\nSTORY:\n\n  #{templated_story}"
  end

  blanks.each_with_index { |blank, index|
    needle = "{#{index + 1}}"
    if templated_story.include?(needle)
      templated_story.gsub!(needle, "{#{blank.id}}")
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
    text: "The history of all hitherto existing society is the history of {1}.\n\nIn the earlier epochs of history we find almost everywhere a complicated arrangement of society into various orders, a manifold gradation of social rank. The ancient people known as the '{2}' had patricians, knights, plebeians, and the famously poor '{3}'. The middle ages had feudal lords, vassals, guild masters, journeymen, apprentices, and {4}. In almost all of these classes, again, subordinate gradations. The modern bourgeois society that has sprouted from the ruins of feudal society, has not done away with {5}.  It has but established {6}, new conditions of oppression, new forms of struggle in place of the old ones.  Our epoch, the epoch of {7}, possesses, however, this distinctive feature: it has simplified {8}. Society as a whole is more and more splitting up into two great hostile camps, into two great classes directly facing each other: {9} and {10}.",
    prompts: [
      {
        phrases: [
          "The history of all hitherto existing society is the history of ____."
          # "The most vexing part of the King of England's day.",
        ],
        tags: [ "phrase", "something_vexing" ]
      },
      {
        phrases: [
          "The latest trendy conspiracy theory claims this ancient ____ society once ruled the world."
          # "A wrong answer for the name of an ancient culture on your high school history quiz.",
          # "Ancient _____ society was divided into patricians, knights, plebeians, and peasants.",
        ],
        tags: [ "noun", "ancient_culture" ]
      },
      {
        phrases: [
          "The worst job to have in ancient rome."
          # "The worst job to have in the previous answer's society"
        ],
        tags: [ "noun", "job" ]
      },
      {
        phrases: [
          "The worst type of person to run into at a party.",
          "The name of the ruling clique in a high school."
        ],
        tags: [ "noun", "type_of_person" ]
      },
      {
        phrases: [
          "What a five year old thinks is the best part of having a day job."
          # Worst part of being this type of person- from prior answer
        ],
        tags: [ "phrase", "job" ]
      },
      {
        phrases: [
          "A new form of bullying invented by cruel tweens.",
          "How Mark Zuckerberg chooses to punish everyone who has left Facebook after his evil AI takes over the world."
        ],
        tags: [ "phrase", "bullying" ]
      },
      {
        phrases: [
          "This activity is most likely to make everyone hate you.",
          "The Age of Men is over. The time of _____ has come."
        ],
        tags: [ "noun", "activity" ]
      },
      {
        phrases: [
          "The most complicated thing about being a toddler.",
          "The most annoying thing about the modern era.",
          "The most distinctive feature of the 2000's."
        ],
        tags: [ "noun", "complicated" ]
      },
      {
        phrases: [
          "You want to be the next best-selling author for young adults. What CATCHY NICKNAME do you use for the evil organization that controls the world?"
        ],
          tags: [ "noun", "bad_guys" ]
      },
      {
        phrases: [
          "You want to be the next best-selling author for young adults. What CATCHY NICKNAME do you use for the scrappy band of rebels that's going to save the world?"
        ],
          tags: [ "noun", "good_guys" ]
      }
    ]
  },
  {
    title: "Short Excerpt from an Essay on a Shakespearen play",
    original_text: 'In his essay "Preposterous Pleasures: Queer Theories and A Midsummer Night\'s Dream", Douglas E. Green explores possible interpretations of alternative sexuality that they find within the text of Shakespeare\'s "A Midsummer Night\'s Dream", in juxtaposition to the proscribed social mores of the culture at the time the play was written. They write that the essay "does not seek to rewrite it as a gay play but rather lend a critical analysis to overlooked themes of this underappreciated work of Shakespeare\'s. Green does not consider Shakespeare to have been a "sexual radical", but that the play represented a "topsy-turvy world" or "temporary holiday" that mediates or negotiates the "discontents of civilization, which while resolved neatly in the story\'s conclusion, do not resolve so neatly in real life. Green writes that theme of "homoeroticism" in the story must be considered in the context of the "culture of early modern England as a commentary on the "aesthetic rigidities of comic form and political ideologies."',
    text: "In his essay 'Preposterous Pleasures: {1}', {2} explores possible interpretations of alternative sexuality that they find within the text of Shakespeare's '{3}', in juxtaposition to the proscribed social mores of the culture at the time the play was written.\n\nThey write that the essay 'does not seek to rewrite '{3}' as a {4} play but rather lend a critical analysis to overlooked themes of this underappreciated work of Shakespeare's.'\n\n{2} does not consider Shakespeare to have been a 'sexual radical', but that the play represented a 'topsy-turvy world' or 'temporary holiday' that mediates or negotiates the 'discontents of civilization', which while resolved neatly in the story's conclusion, do not resolve so neatly in real life.' They write that the theme of '{5}' in the story must be considered in the context of the 'culture of {6}' as a commentary on the 'aesthetic rigidities of comic form and political ideologies.'",
    prompts: [
      {
        phrases: [
          "What is a made-up title of an academic essay about sex that was required reading in your high school english class?"
        ],
        tags: [ "title", "essay", "sex", "shakespeare_play" ]
      },
      {
        phrases: [
          "What is the worst possible name for a literary critic or academic author?"
        ],
        tags: [ "name", "author", "shakespeare_play" ]
      },
      {
        phrases: [
          "Historians have located a long-lost Shakespearean play. Surprisingly, its named: _____."
        ],
        tags: [ "title", "long_lost_shakespearean_play", "shakespeare_play" ]
      },
      {
        phrases: [
          "What is the worst adjective to describe a Radical Movement's Agenda?"
        ],
        tags: [ "adjective", "radical_agenda", "shakespeare_play" ]
      },
      {
        phrases: [
          "What theme does your English teacher insist is in this play, but no matter how much you look, you can't find it?"
        ],
        tags: [ "literary_theme", "english_class", "shakespeare_play" ]
      },
      {
        phrases: [
          "What is your neighbor's most annoying hobby?"
        ],
        tags: [ "noun", "activity", "shakespeare_play" ]
      }
    ]
  },
  {
    title: "A Fable on Gluttony",
    original_text: "A VERY HUNGRY FOX, seeing some bread and meat left by shepherds in the hollow of an oak, crept into the hole and made a hearty meal. When he finished, he was so full that he was not able to get out, and began to groan and lament his fate. Another Fox passing by heard his cries, and coming up, inquired the cause of his complaining. On learning what had happened, he said to him, “Ah, you will have to remain there, my friend, until you become such as you were when you crept in, and then you will easily get out.”",
    text: "A VERY HUNGRY {1}, seeing some {2} and {3} left by a {4} in the hollow of an oak, crept into the hole and made a hearty meal. When she finished, she was so full that she was not able to get out, and began to {5} and lament her fate. Another {6} passing by heard her cries, and coming up, inquired the cause of her complaining. On learning what had happened, it said to her, “{7}”",
    prompts: [
      {
        phrases: [
          "The worst creature to find out is actually made in God's image.",
          "Your love interest is a 10, but has a pet _____.",
          "Oh no! A radioactive ____ just came out of the ocean!"
        ],
        tags: [ "noun", "animal", "aesops_fable" ]
      },
      {
        phrases: [
          "Dying of thirst in a desert. You see a sign for this drink and decide to crawl the opposite direction.",
          "Oh no! The wings you ate were covered in ghost pepper hot sauce, but the only thing you have to drink is _____.",
          "They say Cleopatra bathed in donkey milk but you heard “random player” bathes in ____."
        ],
        tags: [ "noun", "drink", "aesops_fable" ]
      },
      {
        phrases: [
        "Stranded on this snowy mountain, our choices for food are _____ or cannibalism. Guess we're choosing cannibalism!",
        "The kids in the schoolyard would trade their whole lunch just for a bite of _____."
        ],
        tags: [ "noun", "food", "aesops_fable" ]
      },
      {
        phrases: [
          "Growing up, my parents said I could choose between being a lawyer, doctor, or _____.",
          "How you might describe your job to a 5 year old."
        ],
        tags: [ "noun", "career", "aesops_fable" ]
      },
      {
        phrases: [
          "After 40 years the Simpsons writers decided to change it up. Homer no longer says “D'oh!” he now says ____ when he messes up.",
          "What is a verb to describe the sound or reaction you make when you stub your toe?"
        ],
        tags: [ "verb", "reaction", "aesops_fable" ]
      },
      {
        phrases: [
          "Baby Shark move over, its time for ______",
          "This year, this mythical beast is the heartthrob of all the teen girl: _____."
        ],
        tags: [ "noun", "animal", "aesops_fable" ]
      },
      {
        phrases: [
          "After a whirlwind adventure the teens wake up in bed, not knowing if it was all a dream or not. The narrator sums up their lesson learnt with this line _____.",
          "My father always warned me ____________ but I never listened.",
          "A phrase you can say to try and sound wise that's actually dumb."
        ],
        tags: [ "phrase", "dumb_wise", "aesops_fable" ]
      }
    ]
  },
  {
    title: "Fast-food Press Release",
    original_text: "People called, and the latest and greatest selling quick-service franchise, {Name a fictional fast-food restaurant.}, is answering. {1}'s beloved {Name a food item this restaurant sells.} are officially back by obsessive demand beginning next at stores nationwide.\n\nFor years, {1} has heard from fans clamoring for a chance to try their famous {What's the BEST adjective to describe this food item?} {2} again, through millions of social media comments and petition signatures.\n\nWhen {1} fired up a surprise drop of {What's the WORST adjective to describe this food item?} {2} in {The city with the worst public bathrooms}, local fans were elated, leading to an early sellout in some restaurants.\n\n{1} first introduced {2} 5 years ago as a menu staple, quickly earning a cult status among fans, before a hotly debated discontinuation last fall that famously lead to one restaurant-goer's arrest after they {How your drunk aunt got arrested in Applebee's.}.\n\n\"{1}-lovers, we heard you—and we agree it's been five long years without {2}. But the wait is over,\" said {The name of the president of this restaurant chain} the President of {1}. \"This isn't just a nostalgic nod. It's an example of how we're turning feedback into action. As we say here at {1}: {Famous catchphrase for this restaurant}\"",
    text: "People called, and the latest and greatest selling quick-service franchise, {1}, is answering. {1}'s beloved {2} are officially back by obsessive demand beginning next at stores nationwide.\n\nFor years, {1} has heard from fans clamoring for a chance to try their famous {3} {2} again, through millions of social media comments and petition signatures.\n\nWhen {1} fired up a surprise drop of {4} {2} in {5}, local fans were elated, leading to an early sellout in some restaurants.\n\n{1} first introduced {2} 5 years ago as a menu staple, quickly earning a cult status among fans, before a hotly debated discontinuation last fall that famously lead to one restaurant-goer's arrest after they {6}.\n\n\"{1}-lovers, we heard you—and we agree it's been five long years without {2}. But the wait is over,\" said {7} the President of {1}. \"This isn't just a nostalgic nod. It's an example of how we're turning feedback into action. As we say here at {1}: '{8}'\"",
    prompts: [
      {
        phrases: [
          "Name a fictional fast-food restaurant.",
          "After the merge, all fast food restaurants became one entity. Its called ______, and it's the ONLY way to get food now."
        ],
        tags: [ "noun", "restaurant", "fictional" ]
      },
      {
        phrases: [
          "Name a food item this restaurant sells.",
          "Guy Fieri's white whale: Even he couldn't finish eating _____."
        ],
        tags: [ "noun", "food", "menu_item" ]
      },
      {
        phrases: [
          "What's the BEST adjective to describe this food item?",
          "Every Christmas you try to make your grandmother's famous recipe but it's never quite as _____ as she used to make it."
        ],
        tags: [ "adjective", "food", "positive" ]
      },
      {
        phrases: [
          "What's the WORST adjective to describe this food item?",
          "Pizza Rat finally made the late night circuit. She shockingly admitted to Jimmy that the pizza was actually kind of ______."
        ],
        tags: [ "adjective", "food", "negative" ]
      },
      {
        phrases: [
          'I went to _____ and everyone said they knew you.',
          'Did you hear? They found a new species of frog. Apparently it was hiding in ______ this whole time.'
        ],
        tags: [ "noun", "city", "funny" ]
      },
      {
        phrases: [
          "How your drunk aunt got arrested in Applebee's."
        ],
        tags: [ "phrase", "incident", "funny" ]
      },
      {
        phrases: [
          "The name of the president of this restaurant chain."
        ],
        tags: [ "name", "person", "president" ]
      },
      {
        phrases: [
          "Famous catchphrase for this restaurant."
        ],
        tags: [ "phrase", "slogan", "restaurant" ]
      }
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
