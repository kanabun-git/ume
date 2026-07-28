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

ActiveRecord::Schema[7.2].define(version: 2026_07_28_140958) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.boolean "hidden", default: false, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "areas", force: :cascade do |t|
    t.string "name", null: false
    t.string "name_kana"
    t.string "slug", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "region"
    t.index ["parent_id"], name: "index_areas_on_parent_id"
    t.index ["slug"], name: "index_areas_on_slug", unique: true
  end

  create_table "cast_page_blocks", force: :cascade do |t|
    t.integer "block_type", null: false
    t.integer "layout_column", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.boolean "visible", default: true, null: false
    t.string "title"
    t.string "background_color"
    t.decimal "background_opacity", precision: 3, scale: 2, default: "1.0", null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "shop_id", null: false
    t.index ["shop_id", "layout_column", "position"], name: "idx_on_shop_id_layout_column_position_8d5867b4ac"
    t.index ["shop_id"], name: "index_cast_page_blocks_on_shop_id"
  end

  create_table "casts", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "user_id"
    t.string "name", null: false
    t.string "alias_name"
    t.integer "age"
    t.integer "height"
    t.integer "bust"
    t.integer "waist"
    t.integer "hip"
    t.string "cup"
    t.string "catch_copy"
    t.text "description"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_trial", default: false, null: false
    t.boolean "manager_recommended", default: false, null: false
    t.text "appeal_comment"
    t.text "manager_comment"
    t.text "selling_points"
    t.text "qa_message"
    t.string "zodiac_sign"
    t.string "blood_type"
    t.boolean "pick_up", default: false, null: false
    t.index ["shop_id"], name: "index_casts_on_shop_id"
    t.index ["user_id"], name: "index_casts_on_user_id", unique: true
  end

  create_table "diary_entries", force: :cascade do |t|
    t.bigint "cast_id", null: false
    t.string "title", null: false
    t.text "body"
    t.integer "status", default: 0, null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cast_id"], name: "index_diary_entries_on_cast_id"
  end

  create_table "genres", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_genres_on_slug", unique: true
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.integer "monthly_fee", default: 0, null: false
    t.integer "priority_weight", default: 1, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "cast_id"
    t.string "reviewer_name", null: false
    t.integer "rating", null: false
    t.text "body", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "shop_reply"
    t.datetime "shop_replied_at"
    t.index ["cast_id"], name: "index_reviews_on_cast_id"
    t.index ["shop_id"], name: "index_reviews_on_shop_id"
  end

  create_table "shifts", force: :cascade do |t|
    t.bigint "cast_id", null: false
    t.date "work_date", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.string "note"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "ends_next_day", default: false, null: false
    t.index ["cast_id"], name: "index_shifts_on_cast_id"
  end

  create_table "shop_page_blocks", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.integer "block_type", null: false
    t.integer "position", default: 0, null: false
    t.boolean "visible", default: true, null: false
    t.string "title"
    t.string "background_color"
    t.decimal "background_opacity", precision: 3, scale: 2, default: "1.0", null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "position"], name: "index_shop_page_blocks_on_shop_id_and_position"
    t.index ["shop_id"], name: "index_shop_page_blocks_on_shop_id"
  end

  create_table "shop_subscriptions", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "plan_id", null: false
    t.date "started_on", null: false
    t.date "ended_on"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_shop_subscriptions_on_plan_id"
    t.index ["shop_id"], name: "index_shop_subscriptions_on_shop_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "area_id", null: false
    t.bigint "genre_id", null: false
    t.bigint "plan_id", null: false
    t.string "catch_copy"
    t.text "description"
    t.string "address"
    t.string "phone"
    t.string "business_hours"
    t.integer "status", default: 0, null: false
    t.integer "view_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "chain_name"
    t.string "price_note"
    t.string "transportation_fee_note"
    t.string "coverage_area_note"
    t.text "coupon_description"
    t.text "recruiting_message"
    t.text "editor_review"
    t.boolean "online_reservation", default: false, null: false
    t.boolean "visit_point_program", default: false, null: false
    t.boolean "coupon_available", default: false, null: false
    t.boolean "event_ongoing", default: false, null: false
    t.boolean "recruiting_cast", default: false, null: false
    t.boolean "recruiting_staff", default: false, null: false
    t.integer "time_display_format", default: 0, null: false
    t.integer "min_price"
    t.index ["area_id"], name: "index_shops_on_area_id"
    t.index ["genre_id"], name: "index_shops_on_genre_id"
    t.index ["plan_id"], name: "index_shops_on_plan_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", default: "", null: false
    t.integer "role", default: 0, null: false
    t.bigint "shop_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["shop_id"], name: "index_users_on_shop_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "areas", "areas", column: "parent_id"
  add_foreign_key "cast_page_blocks", "shops"
  add_foreign_key "casts", "shops"
  add_foreign_key "casts", "users"
  add_foreign_key "diary_entries", "casts"
  add_foreign_key "reviews", "casts"
  add_foreign_key "reviews", "shops"
  add_foreign_key "shifts", "casts"
  add_foreign_key "shop_page_blocks", "shops"
  add_foreign_key "shop_subscriptions", "plans"
  add_foreign_key "shop_subscriptions", "shops"
  add_foreign_key "shops", "areas"
  add_foreign_key "shops", "genres"
  add_foreign_key "shops", "plans"
  add_foreign_key "users", "shops"
end
