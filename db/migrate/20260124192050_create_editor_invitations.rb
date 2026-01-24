class CreateEditorInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :editor_invitations do |t|
      t.string :email, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.references :editor, foreign_key: true

      t.timestamps
    end
    add_index :editor_invitations, :email
    add_index :editor_invitations, :token_digest, unique: true
  end
end
