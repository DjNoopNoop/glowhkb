class User < ApplicationRecord
  has_secure_password

  # Virtual attribute for raw reset token (not saved)
  attr_accessor :reset_token

  has_many :submissions, dependent: :nullify

  STATUSES = [
    PENDING = 'pending'.freeze,
    DENIED = 'denied'.freeze,
    ACTIVE = 'active'.freeze
  ].freeze

  ROLES = [
    CONTRIBUTOR = 'contributor'.freeze,
    ADJUDICATOR = 'adjudicator'.freeze,
    ADMINISTRATOR = 'administrator'.freeze
  ].freeze

  def self.public_roles
    [CONTRIBUTOR, ADJUDICATOR].freeze
  end

  # Scopes for statuses
  scope :pending, -> { where(status: PENDING) }
  scope :active, -> { where(status: ACTIVE) }
  scope :denied, -> { where(status: DENIED) }

  # Scopes for roles
  scope :contributors, -> { where(role: CONTRIBUTOR) }
  scope :adjudicators, -> { where(role: ADJUDICATOR) }
  scope :administrators, -> { where(role: ADMINISTRATOR) }

  # Instance methods to change status
  def activate!
    update!(status: ACTIVE)
  end

  # PASSWORD RESET helpers
  require 'securerandom'

  # Returns the hash digest of the given string.
  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a new random token.
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest: User.digest(reset_token), reset_sent_at: Time.current)
  end

  # Sends password reset email using PasswordMailer
  def send_password_reset_email
    PasswordMailer.password_reset(self).deliver_later
  end

  # Returns true if the given token matches the digest for the attribute.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.blank?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Check if a password reset has expired (2 hours)
  def password_reset_expired?
    reset_sent_at.nil? || reset_sent_at < 2.hours.ago
  end

  def deny!
    update!(status: DENIED)
  end

  # Role predicate helpers
  def is_admin?
    role == ADMINISTRATOR
  end

  def is_adjudicator?
    role == ADJUDICATOR || is_admin?
  end

  def is_contributor?
    role == CONTRIBUTOR || is_adjudicator?
  end

  # Status predicate helpers
  def active?
    status == ACTIVE
  end

  def pending?
    status == PENDING
  end

  def denied?
    status == DENIED
  end

  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :role, presence: true, inclusion: { in: ROLES }

  after_initialize :set_default_status_and_role, if: :new_record?

  private

  def set_default_status_and_role
    self[:status] ||= PENDING
    self[:role] ||= CONTRIBUTOR
  end
end
