Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"

  get "global/map", to: "global#map", as: :global_map
  get "global/search", to: "global#search", as: :global_search
  get "autocomplete/:resource", to: "autocomplete#search", as: :autocomplete
  
  resources :users, only: %i[new create edit update show]
  get "/signup", to: "users#new", as: :signup

  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  resources :publications
end
