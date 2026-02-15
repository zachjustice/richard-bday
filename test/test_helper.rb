ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Windows lacks fork() so can't use process-based parallelism,
    # and threaded parallelism causes SQLite locking issues. Run serially on Windows.
    if ENV["CI"] || !Gem.win_platform?
      parallelize(workers: :number_of_processors, with: :processes)
    else
      parallelize(workers: 1)
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Helper method to authenticate as a user in integration tests
    def resume_session_as(code, name)
      post "/session/resume", params: {
        code: code,
        name: name
      }
    end

    def end_session
      delete "/session"
    end

    # Helper method to authenticate as an editor in integration tests
    def sign_in_as_editor(editor_or_session)
      editor = if editor_or_session.is_a?(EditorSession)
        editor_or_session.editor
      else
        editor_or_session
      end
      post "/editor/login", params: {
        username: editor.username,
        password: "password123"
      }
    end

    def sign_out_editor
      delete "/editor/logout"
    end
  end
end
