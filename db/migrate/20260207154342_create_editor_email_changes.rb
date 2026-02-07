class CreateEditorEmailChanges < ActiveRecord::Migration[8.0]
  def change
    create_table :editor_email_changes do |t|
      t.references :editor, null: false, foreign_key: true
      t.string :new_email, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end
    add_index :editor_email_changes, :token_digest, unique: true
  end
end
