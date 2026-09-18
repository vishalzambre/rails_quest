Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  get  "register", to: "registrations#new", as: :register
  post "register", to: "registrations#create"
  get  "instructions", to: "games#instructions", as: :instructions
  get  "play", to: "games#show", as: :play
  get  "results/:token", to: "results#show", as: :result

  get "leaderboard", to: "leaderboards#show"
  get "leaderboard/today", to: "leaderboards#today", as: :today_leaderboard
  get "leaderboard/conference", to: "leaderboards#conference", as: :conference_leaderboard

  namespace :admin do
    get    "login",  to: "sessions#new"
    post   "login",  to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    root to: "dashboard#show"

    resources :players, only: %i[index show]
    resources :questions do
      member do
        post :toggle
      end
    end
    resources :game_levels, only: %i[index edit update]
    resource  :game_configuration, only: %i[show update]
    resources :game_sessions, only: %i[index show] do
      collection do
        get :suspicious
      end
    end
    resource :leaderboard, only: %i[show destroy], controller: "leaderboards"
    get "analytics", to: "analytics#show"
    get "exports/results", to: "exports#results", as: :export_results
  end

  namespace :api do
    namespace :v1 do
      resources :players, only: :create
      resources :game_sessions, param: :token, only: %i[create show] do
        member do
          post :start
          post :events
          post :finish
          post :challenge
        end
        resources :questions, only: [] do
          member do
            post :answer
          end
        end
      end
      get "leaderboard", to: "leaderboards#show"
      get "stats", to: "stats#show"
    end
  end
end
