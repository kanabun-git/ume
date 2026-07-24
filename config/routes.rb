Rails.application.routes.draw do
  devise_for :users

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "home#index"

  get "rankings", to: "rankings#index", as: :rankings

  resources :areas, only: [:show], param: :slug
  resources :genres, only: [:show], param: :slug
  resources :casts, only: [:show]
  resources :shops, only: [:index, :show] do
    resources :reviews, only: [:new, :create]
  end

  # --- Cast (女の子) dashboard: manage own profile, diary, shifts ---
  # `module: "cast_portal"` avoids clashing with the top-level Cast model
  # (a bare `namespace :cast` would try to reopen the Cast class as a module).
  namespace :cast, module: "cast_portal" do
    root to: "dashboard#show"
    resource :profile, only: [:edit, :update]
    resources :diary_entries
    resources :shifts
  end

  # --- Shop admin dashboard: manage own shop's content ---
  namespace :shop_admin do
    root to: "dashboard#show"
    resource :shop, only: [:edit, :update]
    resources :casts
    resources :diary_entries, only: [:index, :show]
    resources :reviews, only: [:index]
  end

  # --- Platform admin (運営者) back office ---
  namespace :admin do
    root to: "dashboard#show"
    resources :shops do
      member do
        patch :approve
        patch :suspend
      end
    end
    resources :areas
    resources :genres
    resources :plans
    resources :shop_subscriptions
    resources :reviews, only: [:index, :show, :destroy] do
      member do
        patch :approve
        patch :reject
      end
    end
    resources :users
  end
end
