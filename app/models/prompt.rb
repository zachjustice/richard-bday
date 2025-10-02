class Prompt < ApplicationRecord
  has_many :answers, dependent: :destroy
end
