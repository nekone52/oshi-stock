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
  resource :registration, only: [ :new, :create ]
  get "signup", to: "registrations#new", as: :signup
  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy

  resources :reservations, only: [ :index ]
  resources :goods, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    member do
      patch :receive
      patch :toggle_paid
    end
  end
  resources :oshis, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    get :confirm_delete, on: :member
  end
  resources :categories, only: [ :create, :destroy ]
  get "start", to: "top#start", as: :start
  get "settings", to: "settings#show", as: :settings
  get "settings/withdraw", to: "settings#withdraw", as: :withdraw
  delete "settings/withdraw", to: "settings#destroy"
  patch "settings", to: "settings#update"
  get "settings/email", to: "settings#edit_email", as: :edit_email
  patch "settings/email", to: "settings#update_email"
end
