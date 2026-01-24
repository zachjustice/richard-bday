class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :editor_session

  delegate :user, to: :session, allow_nil: true
  delegate :editor, to: :editor_session, allow_nil: true
end
