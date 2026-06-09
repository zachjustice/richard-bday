class DevPhaseSimulatorService
  Success = Data.define(:room)
  Failure = Data.define(:error)

  SUPPORTED_STATUSES = [
    RoomStatus::WaitingRoom,
    RoomStatus::StorySelection,
    RoomStatus::Answering,
    RoomStatus::Voting,
    RoomStatus::Results,
    RoomStatus::FinalResults,
    RoomStatus::Credits
  ].freeze

  DEFAULT_PLAYER_COUNT_FOR_ANSWERING = User::MAX_PLAYERS
  DEFAULT_AUDIENCE_COUNT_FOR_RESULTS = User::MAX_AUDIENCE
  PHASES_THAT_NEED_FULL_GAME = [
    RoomStatus::Answering,
    RoomStatus::Voting,
    RoomStatus::Results,
    RoomStatus::FinalResults,
    RoomStatus::Credits
  ].freeze
  PHASES_THAT_NEED_AUDIENCE = [
    RoomStatus::Results,
    RoomStatus::FinalResults,
    RoomStatus::Credits
  ].freeze

  def initialize(room:, target_status:, player_count: nil, audience_count: nil)
    @room = room
    @target_status = target_status
    @player_count = player_count
    @audience_count = audience_count
  end

  def call
    unless SUPPORTED_STATUSES.include?(@target_status)
      return Failure.new(error: "Unsupported target_status: #{@target_status.inspect}. Supported: #{SUPPORTED_STATUSES.inspect}")
    end

    if PHASES_THAT_NEED_FULL_GAME.include?(@target_status)
      @player_count ||= DEFAULT_PLAYER_COUNT_FOR_ANSWERING
    end

    if PHASES_THAT_NEED_AUDIENCE.include?(@target_status)
      @audience_count ||= DEFAULT_AUDIENCE_COUNT_FOR_RESULTS
    end

    seed_users if @player_count || @audience_count

    return Success.new(room: @room) if at_target_phase?

    case @target_status
    when RoomStatus::WaitingRoom
      seed_waiting_room
    when RoomStatus::StorySelection
      seed_story_selection
    when RoomStatus::Answering
      seed_answering
    when RoomStatus::Voting
      seed_voting
    when RoomStatus::Results
      seed_results
    when RoomStatus::FinalResults
      seed_final_results
    when RoomStatus::Credits
      seed_credits
    end

    Success.new(room: @room)
  end

  private

  def at_target_phase?
    return false unless @room.status == @target_status

    case @target_status
    when RoomStatus::Answering
      @room.current_game&.dev_seeded? && @room.current_game.current_game_prompt_id.present?
    when RoomStatus::Voting
      return false unless @room.current_game&.dev_seeded? && @room.current_game.current_game_prompt_id.present?
      players = User.players.where(room: @room)
      players.any? && players.all? { |p| Answer.exists?(user_id: p.id, game_prompt_id: @room.current_game.current_game_prompt_id, game_id: @room.current_game_id) }
    when RoomStatus::Results
      return false unless @room.current_game&.dev_seeded? && @room.current_game.current_game_prompt_id.present?
      Answer.exists?(game_prompt_id: @room.current_game.current_game_prompt_id, won: true)
    when RoomStatus::FinalResults, RoomStatus::Credits
      return false unless @room.current_game&.dev_seeded?
      prompt_ids = GamePrompt.where(game_id: @room.current_game_id).pluck(:id)
      prompt_ids.any? && prompt_ids.all? { |id| Answer.exists?(game_prompt_id: id, won: true) }
    else
      true
    end
  end

  def seed_waiting_room
    if @room.current_game
      @room.current_game.update!(current_game_prompt: nil, dev_seeded: true)
    end
    @room.update!(
      status: RoomStatus::WaitingRoom,
      current_game: nil
    )
  end

  def seed_story_selection
    @room.update!(
      status: RoomStatus::StorySelection,
      current_game: nil
    )
  end

  def seed_answering
    story = Story.where(published: true).order(:title).first
    if story.nil?
      raise "DevPhaseSimulator cannot seed Answering: no published stories exist (Story.where(published: true).order(:title).first returned nil)"
    end

    game = Game.create!(story: story, room: @room, dev_seeded: true)
    first_game_prompt = create_game_prompts(story, game).first

    game.update!(current_game_prompt: first_game_prompt)
    @room.update!(
      status: RoomStatus::Answering,
      current_game: game
    )

    User.players.where(room: @room).update_all(status: UserStatus::Answering)
  end

  def seed_voting
    ensure_dev_seeded_game_with_prompt

    game = @room.current_game
    seed_answers_for(game, game.current_game_prompt)

    User.players.where(room: @room).update_all(status: UserStatus::Voting)
    @room.update!(status: RoomStatus::Voting)
  end

  def seed_answers_for(game, game_prompt)
    User.players.where(room: @room).find_each do |player|
      next if Answer.exists?(user_id: player.id, game_prompt_id: game_prompt.id, game_id: game.id)
      Answer.create!(
        user: player,
        game_prompt: game_prompt,
        game: game,
        text: Faker::Lorem.sentence(word_count: rand(5...20)).gsub(".", "")[0...150]
      )
    end
  end

  def ensure_dev_seeded_game_with_prompt
    return if @room.current_game&.dev_seeded? && @room.current_game.current_game_prompt_id.present?
    seed_answering
  end

  def seed_results
    # Idempotent: seed_voting backfills game/prompt/answers for any missing players
    # without re-creating the game, and inserts player Answers only where missing.
    seed_voting

    game = @room.current_game
    game_prompt = game.current_game_prompt

    seed_player_votes(game, game_prompt)
    seed_audience_votes(game, game_prompt)

    SelectWinnerService.new(game_prompt, @room).call

    User.players.where(room: @room).update_all(status: UserStatus::Voted)
    @room.update!(status: RoomStatus::Results)
  end

  def seed_final_results
    ensure_dev_seeded_game_with_prompt

    game = @room.current_game
    prompts = GamePrompt.where(game_id: game.id).order(:order)

    prompts.each do |gp|
      game.update!(current_game_prompt: gp) unless game.current_game_prompt_id == gp.id
      seed_answers_for(game, gp)
      seed_player_votes(game, gp)
      seed_audience_votes(game, gp)
      SelectWinnerService.new(gp, @room).call
    end

    User.players.where(room: @room).update_all(status: UserStatus::Voted)
    @room.update!(status: RoomStatus::FinalResults)
  end

  def seed_credits
    seed_final_results
    @room.update!(status: RoomStatus::Credits)
  end

  def seed_player_votes(game, game_prompt)
    answers = Answer.where(game_prompt_id: game_prompt.id, game_id: game.id).to_a
    return if answers.empty?

    voted_user_ids = Vote.by_players.where(game_prompt_id: game_prompt.id).pluck(:user_id).to_set
    now = Time.current
    records = []

    User.players.where(room: @room).find_each do |player|
      next if voted_user_ids.include?(player.id)
      other_answers = answers.reject { |a| a.user_id == player.id }
      next if other_answers.empty?

      if @room.ranked_voting?
        other_answers.first(@room.max_ranks).each_with_index do |answer, idx|
          records << vote_attrs(player.id, answer.id, game.id, game_prompt.id, idx + 1, "player", now)
        end
      else
        records << vote_attrs(player.id, other_answers.first.id, game.id, game_prompt.id, nil, "player", now)
      end
    end

    Vote.insert_all!(records) if records.any?
  end

  def seed_audience_votes(game, game_prompt)
    audience_members = User.audience.where(room: @room).to_a
    answers = Answer.where(game_prompt_id: game_prompt.id, game_id: game.id).to_a
    return if audience_members.empty? || answers.empty?

    voted_audience_ids = Vote.by_audience.where(game_prompt_id: game_prompt.id).pluck(:user_id).to_set
    now = Time.current
    records = []

    audience_members.each do |aud|
      next if voted_audience_ids.include?(aud.id)
      stars = rand(1..Vote::MAX_AUDIENCE_KUDOS)
      stars.times do
        records << vote_attrs(aud.id, answers.sample.id, game.id, game_prompt.id, nil, "audience", now)
      end
    end

    Vote.insert_all!(records) if records.any?
  end

  def vote_attrs(user_id, answer_id, game_id, game_prompt_id, rank, vote_type, now)
    {
      user_id: user_id,
      answer_id: answer_id,
      game_id: game_id,
      game_prompt_id: game_prompt_id,
      rank: rank,
      vote_type: vote_type,
      created_at: now,
      updated_at: now
    }
  end

  def create_game_prompts(story, game)
    blanks = Blank.where(story_id: story.id).order(:id)
    selected_prompts = []
    blanks.map.with_index do |blank, order|
      available = StoryPrompt.where(blank: blank).where.not(prompt_id: selected_prompts).order(:id)
      if available.empty?
        raise "DevPhaseSimulator: no prompts available for blank #{blank.id} (tags: #{blank.tags}) in story #{story.id}"
      end
      story_prompt = available.first
      selected_prompts << story_prompt.prompt_id
      GamePrompt.create!(
        game: game,
        prompt: story_prompt.prompt,
        blank: blank,
        order: order
      )
    end
  end

  def seed_users
    if @player_count
      target_players = @player_count.to_i
      current_player_count = User.players.where(room: @room).count

      if target_players > current_player_count
        Faker::Name.unique.clear
        (target_players - current_player_count).times do
          User.create!(
            room: @room,
            name: unique_fake_name(@room),
            role: User::PLAYER
          )
        end
      elsif target_players < current_player_count && PHASES_THAT_NEED_FULL_GAME.include?(@target_status)
        excess = current_player_count - target_players
        to_trim = fake_players_scope(@room).order(:created_at).limit(excess)
        destroy_users_and_related(to_trim)
      end
    end

    if @audience_count
      target_audience = @audience_count.to_i
      current_audience_count = User.audience.where(room: @room).count

      if target_audience > current_audience_count
        (target_audience - current_audience_count).times do
          User.create!(
            room: @room,
            name: "DevAud#{SecureRandom.hex(3)}",
            role: User::AUDIENCE
          )
        end
      elsif target_audience < current_audience_count && PHASES_THAT_NEED_AUDIENCE.include?(@target_status)
        excess = current_audience_count - target_audience
        to_trim = fake_audience_scope(@room).order(:created_at).limit(excess)
        destroy_users_and_related(to_trim)
      end
    end
  end

  # A real player has a discord_id (Discord activity) or at least one Session
  # (web flow). Fake players have neither, so we trim only those.
  def fake_players_scope(room)
    User.players.where(room: room, discord_id: nil).where.missing(:sessions)
  end

  # Same heuristic for audience members.
  def fake_audience_scope(room)
    User.audience.where(room: room, discord_id: nil).where.missing(:sessions)
  end

  # FK cleanup before destroy_all — fake users may have Vote/Answer rows from a
  # prior phase seed (e.g. trimming after a Results call left votes behind).
  # Neither Vote nor Answer is wired to cascade from User on the DB side.
  def destroy_users_and_related(user_scope)
    user_ids = user_scope.pluck(:id)
    return if user_ids.empty?
    Vote.where(user_id: user_ids).delete_all
    Answer.where(user_id: user_ids).delete_all
    User.where(id: user_ids).destroy_all
  end

  def unique_fake_name(room)
    existing_names = User.where(room: room).pluck(:name).to_set
    10.times do
      candidate = Faker::Name.unique.name[0...15]
      return candidate unless existing_names.include?(candidate)
    end
    "DevPlayer#{SecureRandom.hex(3)}"
  end
end
