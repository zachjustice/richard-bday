class Room < ApplicationRecord
  validates :code, presence: true
end
