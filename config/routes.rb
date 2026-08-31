Rails.application.routes.draw do
  devise_for :users
  devise_for :members

  resources :favorites, only: [:create, :destroy], param: :cast_id
  resources :shop_favorites, only: [:create, :destroy], param: :shop_id
  resources :present_ticket_entries, only: [:create, :destroy]

  # --- Individual member (個人会員) mypage: favorited casts + their shift
  # and diary updates --- `module: "member_portal"` mirrors the cast/
  # cast_portal split (avoids a bare `namespace :member` reopening nothing
  # in particular, and keeps Devise's own /members/* routes untouched).
  namespace :member, module: "member_portal" do
    root to: "mypage#show"
    resource :phone_verification, only: [:new, :create, :edit, :update]
    resources :shop_memberships, only: [:index, :show]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Age-gate / region-picker splash page shown before the region-scoped
  # TOP page (see HomeController#index below).
  root "top#index"
  get "kanto", to: "home#index", defaults: { region: "関東" }, as: :kanto_home
  get "chubu", to: "home#index", defaults: { region: "中部" }, as: :chubu_home

  get "rankings", to: "rankings#index", as: :rankings
  get "today_shifts", to: "today_shifts#index", as: :today_shifts
  get "sitemap.xml", to: "sitemap#index", as: :sitemap, defaults: { format: "xml" }

  resources :videos, only: [:index]
  resources :coupons, only: [:index] do
    member { get :click_reservation }
  end
  resources :diary_entries, only: [:index]
  resources :areas, only: [:show], param: :slug
  resources :genres, only: [:show], param: :slug
  resources :casts, only: [:index, :show]
  resources :shops, only: [:index, :show] do
    resources :reviews, only: [:new, :create] do
      member { post :helpful }
    end
    resource :shop_membership, only: [:create]
  end
  resources :shop_inquiries, only: [:new, :create]
  get "outreach/:token", to: "shop_prospect_outreach#click", as: :shop_prospect_outreach

  # --- Cast (女の子) dashboard: manage own profile, diary, shifts ---
  # `module: "cast_portal"` avoids clashing with the top-level Cast model
  # (a bare `namespace :cast` would try to reopen the Cast class as a module).
  #
  # When CAST_PORTAL_HOST is set (production), these routes only resolve on
  # that dedicated, unbranded domain -- visiting /cast/* on the main site
  # domain 404s, so casts get a discreet URL that doesn't reveal what the
  # site is to anyone glancing at their phone. It's still the same app/DB
  # (see ApplicationHelper#discreet_cast_portal_host? for the matching
  # layout/branding switch); left unconstrained in development/test so
  # local work doesn't need a second hostname configured.
  cast_portal_routes = lambda do
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
  end

  if ENV["CAST_PORTAL_HOST"].present?
    constraints(host: ENV["CAST_PORTAL_HOST"], &cast_portal_routes)
  else
    cast_portal_routes.call
  end

  # --- 有限会社ピュアミント コーポレートサイト (puremint.jp) ---
  # 風俗ポータル本体(FuzokuZero)とは無関係な、運営会社そのものの紹介サイト。
  # PUREMINT_HOST を設定すると(本番ではwww.puremint.jpを想定)、そのドメイン
  # でしか開けなくなる -- 他の2サイトと同じ仕組み(CAST_PORTAL_HOST/
  # MAIL_ADMIN_HOSTのconstraints参照)。開発・テストではホスト名を用意
  # しなくても触れるよう制約を外す。
  corporate_routes = lambda do
    namespace :corporate do
      root to: "pages#index"
      get "company", to: "pages#company", as: :company
      get "business", to: "pages#business", as: :business
      get "access", to: "pages#access", as: :access
      resources :inquiries, only: [:new, :create]
    end
  end

  if ENV["PUREMINT_HOST"].present?
    constraints(host: ENV["PUREMINT_HOST"], &corporate_routes)
  else
    corporate_routes.call
  end

  # --- メールアドレス管理画面 (/mailadmin) ---
  # 運営しているサイト(fuzoku-zero.com / kanabun.tech / puremint.jp)の
  # メールアドレスを追加・削除するための、ポータルサイトとは切り離した管理画面。
  #
  # MAIL_ADMIN_HOST を設定すると、そのドメインでしか開けなくなる
  # (本番では www.kanabun.tech を想定。キャストポータルと同じ仕組みで、
  # ポータルサイトのドメインで /mailadmin を開くと404になる)。
  # 開発・テストではホスト名を用意しなくても触れるよう制約を外す。
  #
  # 一覧(#index)が管理画面そのもので、新規登録フォームも同じ画面に並ぶため
  # :new は使わない。
  mail_admin_routes = lambda do
    namespace :mailadmin, module: "mail_admin", as: "mail_admin" do
      root to: "mail_domains#index"
      resources :mail_domains, except: [:show, :new] do
        resources :mail_accounts, only: [:create]
      end
      resources :mail_accounts, only: [:update, :destroy] do
        member do
          post :test_delivery
          post :round_trip_test
        end
        collection { post :sync }
        # 受信箱を見る(閲覧専用)。:id はDBのレコードIDではなくIMAPのUID。
        resources :messages, only: [:index, :show], controller: "mail_account_messages"
      end
    end
  end

  if ENV["MAIL_ADMIN_HOST"].present?
    constraints(host: ENV["MAIL_ADMIN_HOST"], &mail_admin_routes)
  else
    mail_admin_routes.call
  end

  # --- Shop admin dashboard: manage own shop's content ---
  namespace :shop_admin do
    root to: "dashboard#show"
    resource :shop, only: [:edit, :update] do
      member do
        patch :publish
        patch :unpublish
        delete :destroy_photo
      end
    end
    resources :casts
    resources :coupons do
      resources :usages, only: [:index, :create], controller: "coupon_usages"
    end
    resources :shifts, only: [:index, :new, :create, :destroy] do
      collection do
        post :import
        get :template
      end
    end
    resources :diary_entries, only: [:index, :show]
    resources :reviews, only: [:index] do
      member { patch :reply }
    end
    resources :review_reply_templates
    resources :shop_page_blocks do
      member do
        patch :move_up
        patch :move_down
        patch :toggle_visibility
        patch :toggle_hide_header
      end
    end
    resources :cast_page_blocks do
      member do
        patch :move_up
        patch :move_down
        patch :toggle_visibility
        patch :toggle_hide_header
      end
    end
    resources :present_tickets do
      member do
        post :draw
        post :send_result_emails
      end
    end
    resources :shop_member_ranks, except: [:show] do
      resources :shop_member_benefits, only: [:new, :create, :edit, :update, :destroy]
    end
    resources :shop_memberships, only: [:index, :show, :update] do
      resources :shop_visits, only: [:create]
      resources :shop_point_redemptions, only: [:create]
      resources :shop_member_benefit_grants, only: [] do
        member { patch :mark_used }
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
        patch :confirm_design
        delete :destroy_photo
      end
      resources :shop_page_blocks, except: [:show] do
        member do
          patch :move_up
          patch :move_down
          patch :toggle_visibility
          patch :toggle_hide_header
        end
      end
      resources :cast_page_blocks, except: [:show] do
        member do
          patch :move_up
          patch :move_down
          patch :toggle_visibility
          patch :toggle_hide_header
        end
      end
      resources :review_reply_templates
      resources :casts
      resources :coupons do
        resources :usages, only: [:create], controller: "coupon_usages"
      end
      resources :shifts, only: [:index, :new, :create, :destroy] do
        collection do
          post :import
          get :template
        end
      end
      resources :diary_entries, only: [:index, :show, :destroy]
      resources :present_tickets do
        member do
          post :draw
          post :send_result_emails
        end
      end
      resources :shop_member_ranks, except: [:show] do
        resources :shop_member_benefits, only: [:new, :create, :edit, :update, :destroy]
      end
      resources :shop_memberships, only: [:index, :show, :update] do
        resources :shop_visits, only: [:create]
        resources :shop_point_redemptions, only: [:create]
        resources :shop_member_benefit_grants, only: [] do
          member { patch :mark_used }
        end
      end
    end
    resources :areas do
      collection do
        post :import
        get :template
        get :export
      end
    end
    resources :genres do
      collection do
        post :import
        get :template
        get :export
      end
    end
    resources :plans do
      collection do
        post :import
        get :template
        get :export
      end
    end
    resources :member_ranks, except: [:show] do
      collection do
        post :import
        get :template
        get :export
      end
    end
    resources :shop_subscriptions
    resources :videos, only: [:index, :new, :create, :edit, :update, :destroy]
    resources :shop_prospects do
      collection do
        post :import
        get :template
        get :export
        post :send_outreach_emails
        delete :destroy_all
      end
    end
    resources :shop_prospect_districts, only: [:index, :edit, :update] do
      member { post :register_area }
    end
    resources :reviews, only: [:index, :show, :destroy] do
      member do
        patch :approve
        patch :reject
        patch :reply
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

    resources :shop_inquiries, only: [:index, :show, :destroy] do
      member do
        patch :update_status
        patch :archive
        patch :unarchive
        patch :reply
      end
      collection { get :archived }
    end

    get "analytics", to: "analytics#index", as: :analytics

    resource :setting, only: [:edit, :update]
    resource :outreach_email_template, only: [:edit, :update]
    resource :shop_inquiry_reply_template, only: [:edit, :update]
    resource :basic_setting, only: [:edit, :update]

    get "data_backups", to: "data_backups#index", as: :data_backups
    get "data_backups/shops", to: "data_backups#shops", as: :data_backups_shops
    get "data_backups/casts", to: "data_backups#casts", as: :data_backups_casts
    get "data_backups/diary_entries", to: "data_backups#diary_entries", as: :data_backups_diary_entries
    get "data_backups/videos", to: "data_backups#videos", as: :data_backups_videos
  end
end
