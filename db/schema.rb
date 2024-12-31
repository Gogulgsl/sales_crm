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

ActiveRecord::Schema.define(version: 2024_12_31_091727) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "sales_teams", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "manager_user_id"
    t.bigint "createdby_user_id"
    t.bigint "updatedby_user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["createdby_user_id"], name: "index_sales_teams_on_createdby_user_id"
    t.index ["manager_user_id"], name: "index_sales_teams_on_manager_user_id"
    t.index ["updatedby_user_id"], name: "index_sales_teams_on_updatedby_user_id"
    t.index ["user_id"], name: "index_sales_teams_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.string "email"
    t.string "mobile_number"
    t.string "role"
    t.bigint "createdby_user_id"
    t.bigint "updatedby_user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["createdby_user_id"], name: "index_users_on_createdby_user_id"
    t.index ["updatedby_user_id"], name: "index_users_on_updatedby_user_id"
  end

  add_foreign_key "sales_teams", "users"
  add_foreign_key "sales_teams", "users", column: "createdby_user_id"
  add_foreign_key "sales_teams", "users", column: "manager_user_id"
  add_foreign_key "sales_teams", "users", column: "updatedby_user_id"
end
