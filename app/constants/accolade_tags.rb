module AccoladeTags
  WINNER = "winner"
  AUDIENCE_FAVORITE = "audience_favorite"

  PODIUM_1ST = "podium_1st"
  PODIUM_2ND = "podium_2nd"
  PODIUM_3RD = "podium_3rd"

  NAUGHTY = "naughty"
  PROLIFIC = "prolific"
  EFFICIENT = "efficient"
  MISSPELLER = "misspeller"
  SLOWPOKE = "slowpoke"
  CROWD_PICK = "crowd_pick"

  PODIUM_TAGS = [ PODIUM_1ST, PODIUM_2ND, PODIUM_3RD ].freeze
  CREDITS_TAGS = [ *PODIUM_TAGS, NAUGHTY, PROLIFIC, EFFICIENT, MISSPELLER, SLOWPOKE, CROWD_PICK ].freeze
end
