class CreateSchools < ActiveRecord::Migration[6.1]
  def change
    create_table :schools do |t|
      t.string :name
      t.string :email
      t.string :lead_source
      t.string :location
      t.string :city
      t.string :state
      t.string :pincode
      t.integer :number_of_students
      t.decimal :avg_fees, precision: 10, scale: 2
      t.string :board
      t.string :website
      t.boolean :part_of_group_school
      t.bigint :group_school_id
      t.bigint :createdby_user_id
      t.bigint :updatedby_user_id
      t.string :latitude
      t.string :longitude
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :schools, :createdby_user_id, name: "index_schools_on_createdby_user_id"
    add_index :schools, :updatedby_user_id, name: "index_schools_on_updatedby_user_id"

    add_foreign_key :schools, :schools, column: :group_school_id
    add_foreign_key :schools, :users, column: :createdby_user_id
    add_foreign_key :schools, :users, column: :updatedby_user_id
  end
end
