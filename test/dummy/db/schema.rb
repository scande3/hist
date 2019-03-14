# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_05_22_200410) do

  create_table "collections", force: :cascade do |t|
    t.string "name", limit: 355
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "doc_extras", force: :cascade do |t|
    t.integer "doc_id"
    t.string "extra_info"
    t.index ["doc_id"], name: "index_doc_extras_on_doc_id"
  end

  create_table "doc_files", force: :cascade do |t|
    t.integer "doc_id"
    t.string "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doc_id"], name: "index_doc_files_on_doc_id"
  end

  create_table "doc_subjects", force: :cascade do |t|
    t.integer "doc_id"
    t.integer "subject_id"
    t.index ["doc_id", "subject_id"], name: "index_doc_to_subjects", unique: true
    t.index ["doc_id"], name: "index_doc_subjects_on_doc_id"
    t.index ["subject_id"], name: "index_doc_subjects_on_subject_id"
  end

  create_table "docs", force: :cascade do |t|
    t.integer "collection_id"
    t.string "title", limit: 355
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_docs_on_collection_id"
  end

  create_table "hist_pendings", force: :cascade do |t|
    t.string "model", null: false
    t.integer "obj_id"
    t.string "whodunnit"
    t.string "extra"
    t.text "data", limit: 1073741823
    t.datetime "discarded_at"
    t.datetime "created_at", precision: 6
    t.index ["discarded_at"], name: "hist_pending_discarded_idy"
    t.index ["model", "obj_id"], name: "index_hist_pendings_on_model_and_obj_id"
  end

  create_table "hist_versions", force: :cascade do |t|
    t.string "model", null: false
    t.integer "obj_id", null: false
    t.string "whodunnit"
    t.string "extra"
    t.text "data", limit: 1073741823
    t.datetime "discarded_at"
    t.datetime "created_at", precision: 6
    t.index ["discarded_at"], name: "hist_version_discarded_idy"
    t.index ["model", "obj_id"], name: "index_hist_versions_on_model_and_obj_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.string "label"
  end

end
