class Prompt < ApplicationRecord
  has_many :answers, dependent: :destroy
  validates :description, presence: true, uniqueness: true
end
