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

ActiveRecord::Schema[8.1].define(version: 2026_08_24_203256) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "maintenance_records", force: :cascade do |t|
    t.integer "cost_cents"
    t.datetime "created_at", null: false
    t.string "currency", default: "COP", null: false
    t.text "notes"
    t.string "part_brand"
    t.bigint "part_type_id", null: false
    t.date "performed_on", null: false
    t.datetime "updated_at", null: false
    t.decimal "usage_at_service", precision: 12, scale: 2, null: false
    t.bigint "vehicle_id", null: false
    t.index ["part_type_id"], name: "index_maintenance_records_on_part_type_id"
    t.index ["vehicle_id", "part_type_id", "usage_at_service"], name: "index_maintenance_records_on_vehicle_part_and_usage"
    t.index ["vehicle_id"], name: "index_maintenance_records_on_vehicle_id"
  end

  create_table "part_types", force: :cascade do |t|
    t.string "applicable_vehicle_types", default: [], null: false, array: true
    t.string "category", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["applicable_vehicle_types"], name: "index_part_types_on_applicable_vehicle_types", using: :gin
    t.index ["category"], name: "index_part_types_on_category"
    t.index ["code"], name: "index_part_types_on_code", unique: true
  end

  create_table "reliability_profiles", force: :cascade do |t|
    t.decimal "characteristic_life", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "life_unit", null: false
    t.bigint "part_type_id", null: false
    t.string "source", default: "engineering_estimate", null: false
    t.datetime "updated_at", null: false
    t.string "vehicle_type", null: false
    t.decimal "weibull_shape", precision: 6, scale: 3, null: false
    t.index ["part_type_id", "vehicle_type"], name: "index_reliability_profiles_on_part_type_id_and_vehicle_type", unique: true
    t.index ["part_type_id"], name: "index_reliability_profiles_on_part_type_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", null: false
    t.string "make", null: false
    t.string "model", null: false
    t.integer "model_year", null: false
    t.string "plate"
    t.jsonb "specs", default: {}, null: false
    t.datetime "updated_at", null: false
    t.string "usage_unit", default: "km", null: false
    t.decimal "usage_value", precision: 12, scale: 2, default: "0.0", null: false
    t.string "vehicle_type", null: false
    t.string "vin"
    t.index ["plate"], name: "index_vehicles_on_plate"
    t.index ["vehicle_type"], name: "index_vehicles_on_vehicle_type"
    t.index ["vin"], name: "index_vehicles_on_vin", unique: true, where: "(vin IS NOT NULL)"
  end

  add_foreign_key "maintenance_records", "part_types"
  add_foreign_key "maintenance_records", "vehicles"
  add_foreign_key "reliability_profiles", "part_types"
end
