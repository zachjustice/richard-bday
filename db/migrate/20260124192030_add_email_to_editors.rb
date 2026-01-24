class AddEmailToEditors < ActiveRecord::Migration[8.0]
  def change
    add_column :editors, :email, :string
    add_index :editors, :email, unique: true
  end
end
