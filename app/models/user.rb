class User < ApplicationRecord
  has_secure_password

  has_many :publications, dependent: :nullify

  validates :email, presence: true, uniqueness: true
end
