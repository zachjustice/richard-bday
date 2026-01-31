namespace :editors do
  desc "Invite a new editor by email"
  task :invite, [ :email ] => :environment do |t, args|
    email = args[:email]&.downcase&.strip

    if email.blank?
      puts "Usage: rake editors:invite[email@example.com]"
      puts "Example: rake editors:invite[neweditor@example.com]"
      exit 1
    end

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      puts "Error: Invalid email format"
      exit 1
    end

    if Editor.exists?(email: email)
      puts "Error: An editor with this email already exists"
      exit 1
    end

    # Check for pending invitation
    existing = EditorInvitation.where(email: email, accepted_at: nil)
                               .where("expires_at > ?", Time.current)
                               .first
    if existing
      puts "Warning: A pending invitation already exists for this email (expires #{existing.expires_at})"
      print "Send a new invitation anyway? [y/N] "
      response = $stdin.gets&.chomp&.downcase
      exit 0 unless response == "y"
    end

    invitation, token = EditorInvitation.create_with_token(email: email)

    if invitation.persisted?
      EditorMailer.invitation(invitation, token).deliver_now
      puts "Invitation sent to #{email}"
      puts "Link expires: #{invitation.expires_at}"

      # Output magic link in non-production environments
      unless Rails.env.production?
        signup_url = Rails.application.routes.url_helpers.editor_signup_url(
          token: token,
          host: Rails.application.config.action_mailer.default_url_options[:host],
          port: Rails.application.config.action_mailer.default_url_options[:port]
        )
        puts "Magic link (dev only): #{signup_url}"
      end
    else
      puts "Failed to create invitation:"
      invitation.errors.full_messages.each { |msg| puts "  - #{msg}" }
      exit 1
    end
  end

  desc "Create a new editor account (non-production only)"
  task :create, [ :username, :password, :email ] => :environment do |t, args|
    if Rails.env.production?
      puts "Error: This task is disabled in production. Use editors:invite instead."
      exit 1
    end

    if args[:username].blank? || args[:password].blank? || args[:email].blank?
      puts "Usage: rails editors:create[username,password,email]"
      puts "Example: rails editors:create[admin,secretpassword123,admin@example.com]"
      exit 1
    end

    editor = Editor.new(
      username: args[:username],
      password: args[:password],
      password_confirmation: args[:password],
      email: args[:email]
    )

    if editor.save
      puts "Editor '#{args[:username]}' with email #{args[:email]} created successfully."
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
      editors.each do |e|
        email_display = e.email.present? ? e.email : "no email"
        puts "  - #{e.username} (#{email_display}, created: #{e.created_at.strftime('%Y-%m-%d')})"
      end
    end
  end

  desc "Delete an editor account"
  task :delete, [ :username ] => :environment do |t, args|
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
