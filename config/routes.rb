Rails.application.routes.draw do
  mount RailsEventStore::Browser => "/res" if Rails.env.development?
  resource :session
  post "/sessions/resume", to: "sessions#resume"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root to: "rooms#show"

  get "/rooms/create", to: "rooms#create", as: :create_room
  post "/rooms/create", to: "rooms#_create"
  get "/rooms/:id/status", to: "rooms#status", as: :room_status
  post "/rooms/:id/start", to: "rooms#start", as: :start_room
  post "/rooms/:id/next", to: "rooms#next", as: :next_room
  post "/rooms/:id/end_game", to: "rooms#end_game", as: :end_room_game

  post "/register", to: "users#create"
  get "/users/:id", to: "users#show"

  get "/prompts/:id", to: "prompts#show"
  get "/prompts/:id/waiting", to: "prompts#waiting"
  get "/prompts/:id/voting", to: "prompts#voting"
  get "/prompts/:id/results", to: "prompts#results"

  post "/answer", to: "answers#create"
  post "/vote", to: "votes#create", as: :votes

  post "/vote", to: "vote#update"
end
