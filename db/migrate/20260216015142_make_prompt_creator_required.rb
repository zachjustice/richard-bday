class MakePromptCreatorRequired < ActiveRecord::Migration[8.0]
  def up
    # Backfill any prompts missing a creator with the first available editor
    editor_id = execute("SELECT id FROM editors LIMIT 1").first&.fetch("id")
    if editor_id
      execute("UPDATE prompts SET creator_id = #{editor_id} WHERE creator_id IS NULL")
    end

    change_column_null :prompts, :creator_id, false
  end

  def down
    change_column_null :prompts, :creator_id, true
  end
end
