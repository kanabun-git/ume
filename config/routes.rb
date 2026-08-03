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
  get "sitemap.xml", to: "sitemap#index", as: :sitemap, defaults: { format: "xml" }

  resources :videos, only: [:index]
  resources :areas, only: [:show], param: :slug
  resources :genres, only: [:show], param: :slug
  resources :casts, only: [:show]
  resources :shops, only: [:index, :show] do
    resources :reviews, only: [:new, :create]
  end
  resources :shop_inquiries, only: [:new, :create]

  # --- Cast (女の子) dashboard: manage own profile, diary, shifts ---
  # `module: "cast_portal"` avoids clashing with the top-level Cast model
  # (a bare `namespace :cast` would try to reopen the Cast class as a module).
  namespace :cast, module: "cast_portal" do
    root to: "dashboard#show"
    resource :profile, only: [:edit, :update]
    resources :diary_entries do
      collection do
        post :generate_draft
      end
    end
    resources :shifts
  end

  # --- Shop admin dashboard: manage own shop's content ---
  namespace :shop_admin do
    root to: "dashboard#show"
    resource :shop, only: [:edit, :update]
    resources :casts
    resources :diary_entries, only: [:index, :show]
    resources :reviews, only: [:index] do
      member { patch :reply }
    end
    resources :shop_page_blocks do
      member do
        patch :move_up
        patch :move_down
        patch :toggle_visibility
      end
    end
    resources :cast_page_blocks do
      member do
        patch :move_up
        patch :move_down
        patch :toggle_visibility
      end
    end
  end

  # --- Platform admin (運営者) back office ---
  namespace :admin do
    root to: "dashboard#show"
    resources :shops do
      member do
        patch :approve
        patch :suspend
      end
      resources :shop_page_blocks, except: [:show] do
        member do
          patch :move_up
          patch :move_down
          patch :toggle_visibility
        end
      end
      resources :cast_page_blocks, except: [:show] do
        member do
          patch :move_up
          patch :move_down
          patch :toggle_visibility
        end
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
    resources :users do
      member { post :issue_account_setup_link }
    end

    # Content moderation screens: review submitted cast/diary photos and
    # hide individual ones without touching the surrounding record.
    resources :cast_images, only: [:index] do
      member { patch :toggle_hidden }
    end
    resources :diary_images, only: [:index] do
      member { patch :toggle_hidden }
    end
    # :id here is a DiaryEntry id (the video is has_one, so there's no
    # separate attachment id to moderate against, unlike :toggle_hidden above).
    patch "diary_entries/:id/toggle_video_hidden", to: "diary_images#toggle_video_hidden", as: :toggle_video_hidden_diary_entry

    resources :shop_inquiries, only: [:index, :show] do
      member { patch :update_status }
    end

    resource :setting, only: [:edit, :update]

    get "data_backups", to: "data_backups#index", as: :data_backups
    get "data_backups/shops", to: "data_backups#shops", as: :data_backups_shops
    get "data_backups/casts", to: "data_backups#casts", as: :data_backups_casts
    get "data_backups/diary_entries", to: "data_backups#diary_entries", as: :data_backups_diary_entries
    get "data_backups/videos", to: "data_backups#videos", as: :data_backups_videos
  end
end
