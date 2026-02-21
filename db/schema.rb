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

ActiveRecord::Schema[7.1].define(version: 2026_02_20_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "publications", force: :cascade do |t|
    t.string "title", null: false
    t.text "authors"
    t.text "institutions"
    t.string "journal"
    t.integer "year"
    t.string "volume"
    t.string "pages"
    t.text "data_source"
    t.text "population"
    t.string "time_frame"
    t.text "diagnosis"
    t.string "emergency_departments"
    t.text "exposure_periods"
    t.string "country_region"
    t.string "subject_type"
    t.string "disease_studied"
    t.text "demographics"
    t.text "race_ethnicity"
    t.text "statistical_methods"
    t.text "pollution_parameters"
    t.text "weather_parameters"
    t.string "odds_ratio"
    t.string "risk_ratio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "url"
    t.index ["country_region"], name: "index_publications_on_country_region"
    t.index ["disease_studied"], name: "index_publications_on_disease_studied"
    t.index ["journal"], name: "index_publications_on_journal"
    t.index ["user_id"], name: "index_publications_on_user_id"
    t.index ["year"], name: "index_publications_on_year"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "publications", "users"
end
