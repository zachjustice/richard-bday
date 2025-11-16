Rails.application.routes.draw do
  resource :session
  post "/session/resume", to: "sessions#resume" unless Rails.env.production?
  get "/session/editor", to: "sessions#editor", as: :session_editor
  post "/session/editor", to: "sessions#create_editor", as: :create_session_editor
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root to: "rooms#create"

  resources :stories do
    resources :blanks, only: [ :create, :update, :destroy ]
  end

  # Add to prompts routes
  # TODO: separate prompts and game_prompts
  get "/prompts", to: "prompts#index", as: :prompts_index
  get "/prompts/new", to: "prompts#new", as: :new_prompt
  post "/prompts", to: "prompts#create_prompt", as: :create_prompt
  get "/prompts/:id/edit", to: "prompts#edit_prompt", as: :edit
  patch "/prompts/:id", to: "prompts#update_prompt", as: :update_prompt
  delete "/prompts/:id", to: "prompts#destroy_prompt", as: :destroy_prompt
  get "/prompts/:id/tooltip", to: "prompts#tooltip", as: :prompt_tooltip

  # rooms
  get "/rooms", to: "rooms#show", as: :show_room
  get "/rooms/create", to: "rooms#create", as: :create_room
  post "/rooms/create", to: "rooms#_create"
  get "/rooms/:id/status", to: "rooms#status", as: :room_status
  post "/rooms/:id/start", to: "rooms#start", as: :start_room
  post "/rooms/:id/next", to: "rooms#next", as: :next_room
  post "/rooms/:id/end_game", to: "rooms#end_game", as: :end_room_game
  patch "/rooms/:id/settings", to: "rooms#update_settings", as: :update_room_settings
  get "/rooms/:id/waiting_for_new_game", to: "rooms#waiting_for_new_game", as: :waiting_for_new_game

  post "/register", to: "users#create"
  get "/users/:id", to: "users#show"

  get "/prompts/:id", to: "prompts#show"
  get "/prompts/:id/waiting", to: "prompts#waiting"
  get "/prompts/:id/voting", to: "prompts#voting"
  get "/prompts/:id/results", to: "prompts#results"

  post "/answer", to: "answers#create"
  post "/vote", to: "votes#create", as: :votes

  post "/vote", to: "vote#update"

  # Copyright page
  get "/copyright", to: "copyright#show", as: :copyright

  # About page
  get "/about", to: "about#show", as: :about

  # Handle 404s
  match "*unmatched", to: "application#not_found_method", via: :all
end
