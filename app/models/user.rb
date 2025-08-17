class User < ApplicationRecord
  validates :name, presence: true
  validates :room, presence: true
end
