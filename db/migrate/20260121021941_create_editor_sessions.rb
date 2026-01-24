class CreateEditorSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :editor_sessions do |t|
      t.references :editor, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
