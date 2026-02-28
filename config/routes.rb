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
  
  # User registration and account routes
  get "/signup", to: "registration#new", as: :signup
  post "/signup", to: "registration#create"
  get "/signup/pending", to: "registration#pending", as: :signup_pending

  get "/account", to: "account#show", as: :account
  get "/account/edit", to: "account#edit", as: :edit_account
  patch "/account", to: "account#update"
  put "/account", to: "account#update"
  get "/updates", to: "site_updates#index", as: :updates
  get "/about", to: "pages#about", as: :about

  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  namespace :admin do
    resources :users, only: [:index, :show, :edit, :update]
    resources :registrants, only: [:index, :show] do
      member do
        patch :approve
        patch :deny
      end
    end
    resources :publications
  end

  namespace :adjudicate do
    resources :submissions, only: [:index, :show] do
      member do
        patch :approve
        patch :deny
      end
    end
  end

  resources :publications, only: [:index, :show]
  resources :submissions
end
