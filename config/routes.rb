Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.

  resource :session
  get "up" => "rails/health#show", as: :rails_health_check
  post "/session/resume", to: "sessions#resume" unless Rails.env.production?

  # Editor authentication
  get "/editor/login", to: "editor_sessions#new", as: :editor_login
  post "/editor/login", to: "editor_sessions#create"
  delete "/editor/logout", to: "editor_sessions#destroy", as: :editor_logout

  # Editor account
  get "/editor/settings", to: "editor_settings#show", as: :editor_settings
  patch "/editor/password", to: "editor_passwords#update", as: :editor_password
  post "/editor/email", to: "editor_emails#create", as: :editor_email
  get "/editor/confirm_email/:token", to: "editor_emails#confirm", as: :editor_confirm_email

  # Editor signup via invitation
  get "/editor/signup/:token", to: "editor_invitations#show", as: :editor_signup
  post "/editor/signup/:token", to: "editor_invitations#create"

  # Password reset
  get "/editor/forgot_password", to: "editor_password_resets#new", as: :editor_forgot_password
  post "/editor/forgot_password", to: "editor_password_resets#create"
  get "/editor/reset_password/:token", to: "editor_password_resets#edit", as: :editor_reset_password
  patch "/editor/reset_password/:token", to: "editor_password_resets#update"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root to: "rooms#create"

  resources :stories do
    resources :blanks, only: [ :create, :edit, :update, :destroy ]
    get "prompts", to: "stories#prompts"
  end

  # Prompt library routes (editor interface)
  get "/prompts", to: "prompts#index", as: :prompts_index
  get "/prompts/new", to: "prompts#new", as: :new_prompt
  post "/prompts", to: "prompts#create_prompt", as: :create_prompt
  get "/prompts/:id/edit", to: "prompts#edit_prompt", as: :edit_prompt
  patch "/prompts/:id", to: "prompts#update_prompt", as: :update_prompt
  delete "/prompts/:id", to: "prompts#destroy_prompt", as: :destroy_prompt

  # GamePrompt gameplay routes (player interface)
  get "/game_prompts/:id", to: "game_prompts#show", as: :game_prompt
  get "/game_prompts/:id/waiting", to: "game_prompts#waiting", as: :game_prompt_waiting
  post "/game_prompts/:id/change_answer", to: "game_prompts#change_answer", as: :change_answer
  get "/game_prompts/:id/voting", to: "game_prompts#voting", as: :game_prompt_voting
  get "/game_prompts/:id/results", to: "game_prompts#results", as: :game_prompt_results
  get "/game_prompts/:id/tooltip", to: "game_prompts#tooltip", as: :game_prompt_tooltip

  # avatar
  patch "/avatar", to: "avatars#update", as: :update_avatar

  # rooms
  get "/rooms", to: "rooms#show", as: :show_room
  get "/rooms/create", to: "rooms#create", as: :create_room
  post "/rooms/create", to: "rooms#_create"
  get "/rooms/:id/status", to: "rooms#status", as: :room_status
  post "/rooms/:id/initialize", to: "rooms#initialize_room", as: :initialize_room
  post "/rooms/:id/start", to: "rooms#start", as: :start_room
  post "/rooms/:id/next", to: "rooms#next", as: :next_room
  post "/rooms/:id/end_game", to: "rooms#end_game", as: :end_room_game
  post "/rooms/:id/credits", to: "rooms#show_credits", as: :room_credits
  post "/rooms/:id/start_new_game", to: "rooms#start_new_game", as: :start_new_room_game
  patch "/rooms/:id/settings", to: "rooms#update_settings", as: :update_room_settings
  get "/rooms/:id/waiting_for_new_game", to: "rooms#waiting_for_new_game", as: :waiting_for_new_game
  get "/rooms/:id/check_navigation", to: "rooms#check_navigation", as: :check_room_navigation


  post "/answer", to: "answers#create"

  post "/vote", to: "votes#create", as: :votes
  post "/vote", to: "vote#update"

  # Music Player
  get "/music_player", to: "music_player#index"

  # Copyright page
  get "/copyright", to: "copyright#show", as: :copyright

  # About page
  get "/about", to: "about#show", as: :about

  # Handle 404s
  match "*unmatched", to: "application#not_found_method", via: :all
end
