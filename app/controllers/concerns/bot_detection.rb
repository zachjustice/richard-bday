module BotDetection
  extend ActiveSupport::Concern

  included do
    before_action :redirect_bots_to_babble
  end

  private

  def redirect_bots_to_babble
    # Check for AI bot user agents
    if ai_bot_detected?
      redirect_to "http://#{request.host}/babble", status: :moved_permanently
    end

    # Check for Firefox AI summaries
    if firefox_ai_detected?
      redirect_to "http://#{request.host}/babble", status: :moved_permanently
    end
  end

  def ai_bot_detected?
    user_agent = request.user_agent.to_s.downcase

    ai_bot_patterns = [
      "addsearchbot", "ai2bot", "ai2bot-dolma", "aihitbot", "amazonbot", "andibot",
      "anthropic-ai", "applebot", "applebot-extended", "awario", "bedrockbot",
      "bigsur.ai", "brightbot 1.0", "bytespider", "ccbot", "chatgpt agent",
      "chatgpt-user", "claude-searchbot", "claude-user", "claude-web", "claudebot",
      "cloudvertexbot", "cohere-ai", "cohere-training-data-crawler", "cotoyogi",
      "crawlspace", "datenbank crawler", "devin", "diffbot", "duckassistbot",
      "echobot bot", "echoboxbot", "facebookbot", "facebookexternalhit",
      "factset_spyderbot", "firecrawlagent", "friendlycrawler", "gemini-deep-research",
      "google-cloudvertexbot", "google-extended", "googleagent-mariner", "googleother",
      "googleother-image", "googleother-video", "gptbot", "iaskspider/2.0",
      "icc-crawler", "imagesiftbot", "img2dataset", "isscyberriskcrawler",
      "kangaroo bot", "linerbot", "meta-externalagent", "meta-externalagent",
      "meta-externalfetcher", "meta-externalfetcher", "mistralai-user",
      "mistralai-user/1.0", "mycentralaiscraperbot", "netestate imprint crawler",
      "novaact", "oai-searchbot", "omgili", "omgilibot", "operator", "pangubot",
      "panscient", "panscient.com", "perplexity-user", "perplexitybot", "petalbot",
      "phindbot", "poseidon research crawler", "qualifiedbot", "quillbot",
      "quillbot.com", "sbintuitionsbot", "scrapy", "semrushbot-ocob",
      "semrushbot-swa", "sidetrade indexer bot", "thinkbot", "tiktokspider",
      "timpibot", "velenpublicwebcrawler", "wardbot", "webzio-extended", "wpbot",
      "yak", "yandexadditional", "yandexadditionalbot", "youbot"
    ]

    ai_bot_patterns.any? { |pattern| user_agent.include?(pattern) }
  end

  def firefox_ai_detected?
    request.headers["X-Firefox-AI"]&.downcase == "1"
  end
end
