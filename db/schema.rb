# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_01_11_085126) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "github_event_trackers", force: :cascade do |t|
    t.bigint "target_id", null: false
    t.bigint "event_id", null: false
    t.string "event_type", null: false
    t.jsonb "meta_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["event_id"], name: "index_github_event_trackers_on_event_id", unique: true
    t.index ["target_id"], name: "index_github_event_trackers_on_target_id"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "target_id", null: false
    t.bigint "target_monitor_id"
    t.binary "run_logs"
    t.jsonb "meta_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["target_id"], name: "index_reports_on_target_id"
    t.index ["target_monitor_id"], name: "index_reports_on_target_monitor_id"
  end

  create_table "stray_reports", force: :cascade do |t|
    t.string "url", null: false
    t.jsonb "meta_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["url"], name: "index_stray_reports_on_url"
  end

  create_table "target_monitors", force: :cascade do |t|
    t.bigint "target_id", null: false
    t.integer "repeat_interval"
    t.boolean "repeat", default: false
    t.string "monitor_type", null: false
    t.jsonb "meta_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["monitor_type"], name: "index_target_monitors_on_monitor_type"
    t.index ["target_id", "monitor_type"], name: "index_target_monitors_on_target_id_and_monitor_type", unique: true
  end

  create_table "target_revisions", force: :cascade do |t|
    t.bigint "target_id", null: false
    t.string "external_id"
    t.string "revision_id", null: false
    t.boolean "ignore", default: false
    t.jsonb "meta_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["external_id", "revision_id"], name: "index_target_revisions_on_external_id_and_revision_id", unique: true
    t.index ["external_id"], name: "index_target_revisions_on_external_id"
    t.index ["ignore"], name: "index_target_revisions_on_ignore"
    t.index ["revision_id"], name: "index_target_revisions_on_revision_id"
    t.index ["target_id"], name: "index_target_revisions_on_target_id"
  end

  create_table "targets", force: :cascade do |t|
    t.string "url"
    t.string "target_type"
    t.string "provider"
    t.jsonb "meta_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "slug"
    t.string "status"
    t.string "external_id", null: false
    t.index ["external_id", "provider", "target_type"], name: "index_targets_on_external_id_and_provider_and_target_type", unique: true
    t.index ["external_id"], name: "index_targets_on_external_id"
    t.index ["provider"], name: "index_targets_on_provider"
    t.index ["slug"], name: "index_targets_on_slug"
    t.index ["status"], name: "index_targets_on_status"
    t.index ["url", "target_type"], name: "index_targets_on_url_and_target_type", unique: true
  end

end
