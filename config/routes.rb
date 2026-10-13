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

  # 予約の一覧(登録はグッズ登録のフォームを「予約中」で開く)
  resources :reservations, only: [ :index ]
  # グッズ(一覧・詳細・登録・編集・削除機能への案内)
  resources :goods, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    # 1つのグッズに対する道(URL に番号が入る)。ホームのワンタップの切り替えで使う
    member do
      patch :receive       # 届いた    PATCH /goods/:id/receive
      patch :toggle_paid   # 支払った  PATCH /goods/:id/toggle_paid
    end
  end
  # 推しキャラ(一覧・登録・編集・削除機能への案内)
  resources :oshis, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    get :confirm_delete, on: :member
  end
  # カテゴリ(グッズの画面のシートから、追加と削除だけ)
  resources :categories, only: [ :create, :destroy ]
  get "start", to: "top#start", as: :start
  get "wishlist", to: "wishlist#index", as: :wishlist
  get "wishlist/new", to: "wishlist#new", as: :new_wishlist
  get "settings", to: "settings#show", as: :settings
  get "settings/withdraw", to: "settings#withdraw", as: :withdraw
  # 退会する(アカウントを消す)。消すので delete。データを変える操作なので get は使わない
  delete "settings/withdraw", to: "settings#destroy"
  # 設定画面で選んだテーマの色を保存する(書きかえなので patch)
  patch "settings", to: "settings#update"
end
