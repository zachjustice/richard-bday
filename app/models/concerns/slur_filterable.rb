# frozen_string_literal: true

module SlurFilterable
  extend ActiveSupport::Concern

  class_methods do
    # Convenience method for validating multiple fields at once
    # Usage: validates_slur_free :name, :bio, message: "contains inappropriate language"
    def validates_slur_free(*attributes, **options)
      validates(*attributes, slur_free: options.presence || true)
    end
  end
end
