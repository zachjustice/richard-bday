class CreateStoryPrompt < ActiveRecord::Migration[8.0]
  def up
    create_table :story_prompts do |t|
      t.references :story, null: false, foreign_key: true
      t.references :blank, null: false, foreign_key: true
      t.references :prompt, null: false, foreign_key: true
      t.timestamps
    end

    add_index :story_prompts, [ :story_id, :blank_id, :prompt_id ], unique: true, name: 'index_story_prompts_stories_blanks_prompts_unique'

    migrate_existing_data
  end

  def down
    drop_table :story_prompts
  end

  private

  def migrate_existing_data
    # For each story, find its blanks and create StoryPrompt associations
    Story.find_each do |story|
      story.blanks.each do |blank|
        # Find all prompts with matching tags
        matching_prompts = Prompt.where(tags: blank.tags)

        if matching_prompts.any?
          matching_prompts.each do |prompt|
            # Create StoryPrompt if it doesn't exist
            StoryPrompt.find_or_create_by!(
              story: story,
              blank: blank,
              prompt: prompt
            )
          end

          puts "  Created #{matching_prompts.count} StoryPrompt(s) for Story #{story.id}, Blank #{blank.id} (tags: #{blank.tags})"
        else
          puts "  WARNING: No prompts found for Story #{story.id}, Blank #{blank.id} (tags: #{blank.tags})"
        end
      end
    end

    total_count = StoryPrompt.count
    puts "Migration complete. Created #{total_count} StoryPrompt records."
  end
end
