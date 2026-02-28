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

ActiveRecord::Schema[7.1].define(version: 2026_02_28_162820) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "air_pollutants", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "geographic_locations", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "medical_conditions", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pub_air_pollutants", id: false, force: :cascade do |t|
    t.bigint "publication_id", null: false
    t.bigint "air_pollutant_id", null: false
    t.index ["air_pollutant_id", "publication_id"], name: "idx_ap_pub"
    t.index ["publication_id", "air_pollutant_id"], name: "idx_pub_ap"
  end

  create_table "pub_medical_conditions", id: false, force: :cascade do |t|
    t.bigint "publication_id", null: false
    t.bigint "medical_condition_id", null: false
    t.index ["medical_condition_id", "publication_id"], name: "idx_mc_pub"
    t.index ["publication_id", "medical_condition_id"], name: "idx_pub_mc"
  end

  create_table "pub_statistical_methods", id: false, force: :cascade do |t|
    t.bigint "publication_id", null: false
    t.bigint "statistical_method_id", null: false
    t.index ["publication_id", "statistical_method_id"], name: "idx_pub_sm"
    t.index ["statistical_method_id", "publication_id"], name: "idx_sm_pub"
  end

  create_table "pub_weather_parameters", id: false, force: :cascade do |t|
    t.bigint "publication_id", null: false
    t.bigint "weather_parameter_id", null: false
    t.index ["publication_id", "weather_parameter_id"], name: "idx_pub_wp"
    t.index ["weather_parameter_id", "publication_id"], name: "idx_wp_pub"
  end

  create_table "publications", force: :cascade do |t|
    t.string "title", null: false
    t.text "authors"
    t.string "journal"
    t.integer "year"
    t.string "doi"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "geographic_location_id"
    t.bigint "submission_id"
    t.index ["geographic_location_id"], name: "index_publications_on_geographic_location_id"
    t.index ["submission_id"], name: "index_publications_on_submission_id"
    t.index ["user_id"], name: "index_publications_on_user_id"
  end

  create_table "statistical_methods", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sub_air_pollutants", id: false, force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "air_pollutant_id", null: false
    t.index ["air_pollutant_id", "submission_id"], name: "idx_ap_sub"
    t.index ["submission_id", "air_pollutant_id"], name: "idx_sub_ap"
  end

  create_table "sub_medical_conditions", id: false, force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "medical_condition_id", null: false
    t.index ["medical_condition_id", "submission_id"], name: "idx_mc_sub"
    t.index ["submission_id", "medical_condition_id"], name: "idx_sub_mc"
  end

  create_table "sub_statistical_methods", id: false, force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "statistical_method_id", null: false
    t.index ["statistical_method_id", "submission_id"], name: "idx_sm_sub"
    t.index ["submission_id", "statistical_method_id"], name: "idx_sub_sm"
  end

  create_table "sub_weather_parameters", id: false, force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "weather_parameter_id", null: false
    t.index ["submission_id", "weather_parameter_id"], name: "idx_sub_wp"
    t.index ["weather_parameter_id", "submission_id"], name: "idx_wp_sub"
  end

  create_table "submissions", force: :cascade do |t|
    t.string "title", null: false
    t.text "authors"
    t.string "journal"
    t.integer "year"
    t.string "doi"
    t.string "url"
    t.bigint "user_id"
    t.bigint "adjudicated_by_id"
    t.datetime "adjudicated_at"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "geographic_location_id"
    t.index ["geographic_location_id"], name: "index_submissions_on_geographic_location_id"
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending", null: false
    t.string "role", default: "contributor", null: false
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_digest"], name: "index_users_on_reset_digest"
  end

  create_table "weather_parameters", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "publications", "geographic_locations"
  add_foreign_key "publications", "submissions"
  add_foreign_key "publications", "users"
  add_foreign_key "submissions", "geographic_locations"
  add_foreign_key "submissions", "users"
  add_foreign_key "submissions", "users", column: "adjudicated_by_id"
end
