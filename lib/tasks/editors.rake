namespace :editors do
  desc "Create a new editor account"
  task :create, [:username, :password] => :environment do |t, args|
    if args[:username].blank? || args[:password].blank?
      puts "Usage: rails editors:create[username,password]"
      puts "Example: rails editors:create[admin,secretpassword123]"
      exit 1
    end

    editor = Editor.new(
      username: args[:username],
      password: args[:password],
      password_confirmation: args[:password]
    )

    if editor.save
      puts "Editor '#{args[:username]}' created successfully."
    else
      puts "Failed to create editor:"
      editor.errors.full_messages.each { |msg| puts "  - #{msg}" }
      exit 1
    end
  end

  desc "List all editors"
  task list: :environment do
    editors = Editor.all
    if editors.empty?
      puts "No editors found."
    else
      puts "Editors:"
      editors.each { |e| puts "  - #{e.username} (created: #{e.created_at})" }
    end
  end

  desc "Delete an editor account"
  task :delete, [:username] => :environment do |t, args|
    editor = Editor.find_by(username: args[:username])
    if editor
      editor.destroy
      puts "Editor '#{args[:username]}' deleted."
    else
      puts "Editor '#{args[:username]}' not found."
      exit 1
    end
  end
end
