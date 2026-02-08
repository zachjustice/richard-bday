class CreateDiscordActivityTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :discord_activity_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.timestamps

      t.index :token_digest, unique: true
    end
  end
end
