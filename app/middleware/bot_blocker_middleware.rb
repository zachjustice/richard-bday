class BotBlockerMiddleware
  def initialize(app)
    @app = app
    @bot_path = "404-v2.html"
    @invalid_extensions = [ "html", "php", "env", "git", "envrc", "old", "log" ]
    @invalid_paths = [
      "phpinfo", "cgi-bin", "bins", "geoserver", "webui", "geoip",
      "boaform", "actuator/health", "developmentserver/metadatauploader", "manager/html"
    ] + @invalid_extensions.map { |ext| ".#{ext}" }
  end

  def call(env)
    request = Rack::Request.new(env)
    path = request.path.to_s

    # Redirect AI bots and Firefox AI early, before Rails
    if ai_bot_detected?(request) || firefox_ai_detected?(request)
      location = "https://#{request.host}/babble"
      return [ 301, { "Location" => location, "Cache-Control" => "no-cache, no-store" }, [] ]
    end

    if fishy_path?(path)
      body = File.read(Rails.public_path.join(@bot_path))
      return [ 200, {
        "Content-Type" => "text/html; charset=utf-8",
        "Cache-Control" => "no-cache, no-store"
      }, [ body ] ]
    end

    @app.call(env)
  end

  private

  def fishy_path?(path)
    return true if @invalid_paths.any? { |needle| path.include?(needle) }

    @invalid_extensions.any? { |ext| path.include?(".#{ext}") }
  end

  def ai_bot_detected?(request)
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

  def firefox_ai_detected?(request)
    header = request.get_header("HTTP_X_FIREFOX_AI")
    header && header.to_s.downcase == "1"
  end
end
