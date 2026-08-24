class User < ApplicationRecord
  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP
  MINIMUM_PASSWORD_LENGTH = 8

  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :vehicles, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, format: { with: EMAIL_FORMAT }, uniqueness: true
  validates :password, length: { minimum: MINIMUM_PASSWORD_LENGTH }, allow_nil: true
end
