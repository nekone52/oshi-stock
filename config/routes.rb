Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "top#index"

  get "login", to: "sessions#new", as: :login
  # 新規登録(画面の表示 new と、登録の create)
  resource :registration, only: [ :new, :create ]
  get "signup", to: "registrations#new", as: :signup
  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy

  # 画面モック(ロジックは後で入れる)
  resources :reservations, only: [ :index, :new ]
  resources :goods, only: [ :index, :new, :edit ]
  resources :oshis, only: [ :index, :show, :new, :edit ] do
    get :confirm_delete, on: :member
  end
  resources :categories, only: [ :new ]
  get "start", to: "top#start", as: :start
  get "wishlist", to: "wishlist#index", as: :wishlist
  get "wishlist/new", to: "wishlist#new", as: :new_wishlist
  get "settings", to: "settings#show", as: :settings
  get "settings/withdraw", to: "settings#withdraw", as: :withdraw
end
