class AddDesignationToContacts < ActiveRecord::Migration[6.1]
  def change
    add_column :contacts, :designation, :string
  end
end
