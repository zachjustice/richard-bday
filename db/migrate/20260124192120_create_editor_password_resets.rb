class CreateEditorPasswordResets < ActiveRecord::Migration[8.0]
  def change
    create_table :editor_password_resets do |t|
      t.references :editor, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end
    add_index :editor_password_resets, :token_digest, unique: true
  end
end
