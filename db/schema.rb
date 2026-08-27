# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_26_220000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.boolean "hidden", default: false, null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "areas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "name_kana"
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.string "region"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_areas_on_parent_id"
    t.index ["slug"], name: "index_areas_on_slug", unique: true
  end

  create_table "cast_daily_views", force: :cascade do |t|
    t.bigint "cast_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "view_date", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["cast_id", "view_date"], name: "index_cast_daily_views_on_cast_id_and_view_date", unique: true
    t.index ["cast_id"], name: "index_cast_daily_views_on_cast_id"
  end

  create_table "cast_page_blocks", force: :cascade do |t|
    t.string "background_color"
    t.decimal "background_opacity", precision: 3, scale: 2, default: "1.0", null: false
    t.integer "block_type", null: false
    t.datetime "created_at", null: false
    t.boolean "hide_header", default: false, null: false
    t.integer "layout_column", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.jsonb "settings", default: {}, null: false
    t.bigint "shop_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["shop_id", "layout_column", "position"], name: "idx_on_shop_id_layout_column_position_8d5867b4ac"
    t.index ["shop_id"], name: "index_cast_page_blocks_on_shop_id"
  end

  create_table "casts", force: :cascade do |t|
    t.integer "age"
    t.string "alias_name"
    t.text "appeal_comment"
    t.string "blood_type"
    t.integer "bust"
    t.string "catch_copy"
    t.datetime "created_at", null: false
    t.string "cup"
    t.text "description"
    t.integer "height"
    t.integer "hip"
    t.boolean "is_trial", default: false, null: false
    t.text "manager_comment"
    t.boolean "manager_recommended", default: false, null: false
    t.string "name", null: false
    t.boolean "pick_up", default: false, null: false
    t.text "qa_message"
    t.text "selling_points"
    t.bigint "shop_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.integer "view_count", default: 0, null: false
    t.integer "waist"
    t.string "zodiac_sign"
    t.index ["shop_id"], name: "index_casts_on_shop_id"
    t.index ["user_id"], name: "index_casts_on_user_id", unique: true
  end

  create_table "coupon_usages", force: :cascade do |t|
    t.bigint "coupon_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "usage_type", default: 0, null: false
    t.index ["coupon_id"], name: "index_coupon_usages_on_coupon_id"
  end

  create_table "coupons", force: :cascade do |t|
    t.bigint "cast_id"
    t.text "conditions"
    t.string "coupon_number"
    t.string "course_name", null: false
    t.datetime "created_at", null: false
    t.integer "discounted_price", null: false
    t.boolean "net_reservation_only", default: false, null: false
    t.integer "position", default: 0, null: false
    t.integer "regular_price", null: false
    t.bigint "shop_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.date "valid_from", null: false
    t.date "valid_until"
    t.index ["cast_id"], name: "index_coupons_on_cast_id"
    t.index ["shop_id"], name: "index_coupons_on_shop_id"
  end

  create_table "diary_entries", force: :cascade do |t|
    t.text "body"
    t.bigint "cast_id", null: false
    t.datetime "created_at", null: false
    t.datetime "favorite_notified_at"
    t.datetime "published_at"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["cast_id"], name: "index_diary_entries_on_cast_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "cast_id", null: false
    t.datetime "created_at", null: false
    t.bigint "member_id", null: false
    t.datetime "updated_at", null: false
    t.index ["cast_id"], name: "index_favorites_on_cast_id"
    t.index ["member_id", "cast_id"], name: "index_favorites_on_member_id_and_cast_id", unique: true
    t.index ["member_id"], name: "index_favorites_on_member_id"
  end

  create_table "genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_genres_on_slug", unique: true
  end

  create_table "mail_accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "last_round_trip_error"
    t.boolean "last_round_trip_succeeded"
    t.datetime "last_round_trip_tested_at"
    t.text "last_test_error"
    t.datetime "last_test_sent_at"
    t.boolean "last_test_succeeded"
    t.string "last_test_to"
    t.string "local_part", null: false
    t.bigint "mail_domain_id", null: false
    t.string "password_hash", null: false
    t.text "stored_password"
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.index ["mail_domain_id", "local_part"], name: "index_mail_accounts_on_mail_domain_id_and_local_part", unique: true
    t.index ["mail_domain_id"], name: "index_mail_accounts_on_mail_domain_id"
  end

  create_table "mail_domains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "domain", null: false
    t.string "mail_server_host"
    t.string "name", null: false
    t.text "note"
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_mail_domains_on_domain", unique: true
  end

  create_table "member_ranks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "min_approved_count", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["min_approved_count"], name: "index_member_ranks_on_min_approved_count", unique: true
  end

  create_table "members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.string "phone_number"
    t.datetime "phone_verified_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_members_on_email", unique: true
    t.index ["reset_password_token"], name: "index_members_on_reset_password_token", unique: true
  end

  create_table "outreach_email_templates", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
  end

  create_table "phone_verification_codes", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "member_id", null: false
    t.string "phone_number", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_phone_verification_codes_on_member_id"
  end

  create_table "plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "monthly_fee", default: 0, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "priority_weight", default: 1, null: false
    t.datetime "updated_at", null: false
  end

  create_table "present_ticket_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "member_id", null: false
    t.datetime "notified_at"
    t.bigint "present_ticket_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_present_ticket_entries_on_member_id"
    t.index ["present_ticket_id", "member_id"], name: "index_ticket_entries_on_ticket_and_member", unique: true
    t.index ["present_ticket_id"], name: "index_present_ticket_entries_on_present_ticket_id"
  end

  create_table "present_tickets", force: :cascade do |t|
    t.integer "capacity", null: false
    t.datetime "created_at", null: false
    t.datetime "deadline_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "shop_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_present_tickets_on_shop_id"
  end

  create_table "review_helpful_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address", null: false
    t.bigint "review_id", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id", "ip_address"], name: "index_review_helpful_votes_on_review_id_and_ip_address", unique: true
    t.index ["review_id"], name: "index_review_helpful_votes_on_review_id"
  end

  create_table "review_reply_templates", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "shop_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_review_reply_templates_on_shop_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "cast_id"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.bigint "member_id"
    t.integer "rating", null: false
    t.string "reviewer_name", null: false
    t.bigint "shop_id", null: false
    t.datetime "shop_replied_at"
    t.text "shop_reply"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["cast_id"], name: "index_reviews_on_cast_id"
    t.index ["member_id"], name: "index_reviews_on_member_id"
    t.index ["shop_id"], name: "index_reviews_on_shop_id"
  end

  create_table "shifts", force: :cascade do |t|
    t.bigint "cast_id", null: false
    t.datetime "created_at", null: false
    t.time "end_time", null: false
    t.boolean "ends_next_day", default: false, null: false
    t.string "note"
    t.time "start_time", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.date "work_date", null: false
    t.index ["cast_id"], name: "index_shifts_on_cast_id"
  end

  create_table "shop_daily_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "shop_id", null: false
    t.datetime "updated_at", null: false
    t.date "view_date", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["shop_id", "view_date"], name: "index_shop_daily_views_on_shop_id_and_view_date", unique: true
    t.index ["shop_id"], name: "index_shop_daily_views_on_shop_id"
  end

  create_table "shop_favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "member_id", null: false
    t.bigint "shop_id", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id", "shop_id"], name: "index_shop_favorites_on_member_id_and_shop_id", unique: true
    t.index ["member_id"], name: "index_shop_favorites_on_member_id"
    t.index ["shop_id"], name: "index_shop_favorites_on_shop_id"
  end

  create_table "shop_inquiries", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "area_note"
    t.string "contact_name", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "message"
    t.string "phone", null: false
    t.string "shop_name", null: false
    t.bigint "shop_prospect_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["shop_prospect_id"], name: "index_shop_inquiries_on_shop_prospect_id"
  end

  create_table "shop_member_benefit_grants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "shop_member_benefit_id", null: false
    t.bigint "shop_membership_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["shop_member_benefit_id"], name: "index_shop_member_benefit_grants_on_shop_member_benefit_id"
    t.index ["shop_membership_id"], name: "index_shop_member_benefit_grants_on_shop_membership_id"
  end

  create_table "shop_member_benefits", force: :cascade do |t|
    t.integer "benefit_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "shop_member_rank_id", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_member_rank_id"], name: "index_shop_member_benefits_on_shop_member_rank_id"
  end

  create_table "shop_member_ranks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "min_visit_count", null: false
    t.string "name", null: false
    t.bigint "shop_id", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "min_visit_count"], name: "index_shop_member_ranks_on_shop_id_and_min_visit_count", unique: true
    t.index ["shop_id"], name: "index_shop_member_ranks_on_shop_id"
  end

  create_table "shop_memberships", force: :cascade do |t|
    t.text "caution_notes"
    t.datetime "created_at", null: false
    t.text "incident_notes"
    t.bigint "member_id", null: false
    t.integer "member_number", null: false
    t.bigint "shop_id", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_shop_memberships_on_member_id"
    t.index ["shop_id", "member_id"], name: "index_shop_memberships_on_shop_id_and_member_id", unique: true
    t.index ["shop_id", "member_number"], name: "index_shop_memberships_on_shop_id_and_member_number", unique: true
    t.index ["shop_id"], name: "index_shop_memberships_on_shop_id"
  end

  create_table "shop_page_blocks", force: :cascade do |t|
    t.string "background_color"
    t.decimal "background_opacity", precision: 3, scale: 2, default: "1.0", null: false
    t.integer "block_type", null: false
    t.datetime "created_at", null: false
    t.boolean "hide_header", default: false, null: false
    t.integer "position", default: 0, null: false
    t.jsonb "settings", default: {}, null: false
    t.bigint "shop_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["shop_id", "position"], name: "index_shop_page_blocks_on_shop_id_and_position"
    t.index ["shop_id"], name: "index_shop_page_blocks_on_shop_id"
  end

  create_table "shop_point_transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.string "reason", null: false
    t.bigint "shop_membership_id", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_membership_id"], name: "index_shop_point_transactions_on_shop_membership_id"
  end

  create_table "shop_prospect_districts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "prefecture", default: "東京", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_shop_prospect_districts_on_name", unique: true
  end

  create_table "shop_prospects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "genre"
    t.string "listing_site_name"
    t.string "listing_url"
    t.text "memo"
    t.string "name", null: false
    t.datetime "outreach_email_sent_at"
    t.datetime "outreach_link_clicked_at"
    t.string "outreach_token", null: false
    t.string "phone"
    t.bigint "shop_prospect_district_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["outreach_token"], name: "index_shop_prospects_on_outreach_token", unique: true
    t.index ["shop_prospect_district_id"], name: "index_shop_prospects_on_shop_prospect_district_id"
  end

  create_table "shop_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ended_on"
    t.bigint "plan_id", null: false
    t.bigint "shop_id", null: false
    t.date "started_on", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_shop_subscriptions_on_plan_id"
    t.index ["shop_id"], name: "index_shop_subscriptions_on_shop_id"
  end

  create_table "shop_visits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "memo"
    t.integer "points_earned", default: 0, null: false
    t.bigint "shop_membership_id", null: false
    t.datetime "updated_at", null: false
    t.date "visited_on", null: false
    t.index ["shop_membership_id"], name: "index_shop_visits_on_shop_membership_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "address"
    t.bigint "area_id", null: false
    t.string "business_hours"
    t.string "catch_copy"
    t.string "chain_name"
    t.boolean "coupon_available", default: false, null: false
    t.text "coupon_description"
    t.string "coverage_area_note"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "editor_review"
    t.boolean "event_ongoing", default: false, null: false
    t.bigint "genre_id", null: false
    t.integer "min_price"
    t.string "name", null: false
    t.boolean "online_reservation", default: false, null: false
    t.string "page_accent_color"
    t.string "page_background_color"
    t.string "page_text_color"
    t.string "phone"
    t.bigint "plan_id", null: false
    t.datetime "pr_badge_until"
    t.string "price_note"
    t.boolean "recruiting_cast", default: false, null: false
    t.text "recruiting_message"
    t.boolean "recruiting_staff", default: false, null: false
    t.integer "status", default: 0, null: false
    t.integer "time_display_format", default: 0, null: false
    t.string "transportation_fee_note"
    t.datetime "updated_at", null: false
    t.integer "view_count", default: 0, null: false
    t.boolean "visit_point_program", default: false, null: false
    t.boolean "zero_recommended", default: false, null: false
    t.index ["area_id"], name: "index_shops_on_area_id"
    t.index ["genre_id"], name: "index_shops_on_genre_id"
    t.index ["plan_id"], name: "index_shops_on_plan_id"
  end

  create_table "site_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "maintenance_message"
    t.boolean "maintenance_mode", default: false, null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.bigint "shop_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["shop_id"], name: "index_users_on_shop_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "areas", "areas", column: "parent_id"
  add_foreign_key "cast_daily_views", "casts"
  add_foreign_key "cast_page_blocks", "shops"
  add_foreign_key "casts", "shops"
  add_foreign_key "casts", "users"
  add_foreign_key "coupon_usages", "coupons"
  add_foreign_key "coupons", "casts"
  add_foreign_key "coupons", "shops"
  add_foreign_key "diary_entries", "casts"
  add_foreign_key "favorites", "casts"
  add_foreign_key "favorites", "members"
  add_foreign_key "mail_accounts", "mail_domains"
  add_foreign_key "phone_verification_codes", "members"
  add_foreign_key "present_ticket_entries", "members"
  add_foreign_key "present_ticket_entries", "present_tickets"
  add_foreign_key "present_tickets", "shops"
  add_foreign_key "review_helpful_votes", "reviews"
  add_foreign_key "review_reply_templates", "shops"
  add_foreign_key "reviews", "casts"
  add_foreign_key "reviews", "members"
  add_foreign_key "reviews", "shops"
  add_foreign_key "shifts", "casts"
  add_foreign_key "shop_daily_views", "shops"
  add_foreign_key "shop_favorites", "members"
  add_foreign_key "shop_favorites", "shops"
  add_foreign_key "shop_inquiries", "shop_prospects"
  add_foreign_key "shop_member_benefit_grants", "shop_member_benefits"
  add_foreign_key "shop_member_benefit_grants", "shop_memberships"
  add_foreign_key "shop_member_benefits", "shop_member_ranks"
  add_foreign_key "shop_member_ranks", "shops"
  add_foreign_key "shop_memberships", "members"
  add_foreign_key "shop_memberships", "shops"
  add_foreign_key "shop_page_blocks", "shops"
  add_foreign_key "shop_point_transactions", "shop_memberships"
  add_foreign_key "shop_prospects", "shop_prospect_districts"
  add_foreign_key "shop_subscriptions", "plans"
  add_foreign_key "shop_subscriptions", "shops"
  add_foreign_key "shop_visits", "shop_memberships"
  add_foreign_key "shops", "areas"
  add_foreign_key "shops", "genres"
  add_foreign_key "shops", "plans"
  add_foreign_key "users", "shops"
end
