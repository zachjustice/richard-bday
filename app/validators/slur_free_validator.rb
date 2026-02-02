# frozen_string_literal: true

class SlurFreeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    detector = SlurDetectorService.new(value)
    if detector.contains_slur?
      record.errors.add(
        attribute,
        options[:message] || "contains inappropriate language"
      )
    end
  end
end
