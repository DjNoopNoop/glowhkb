class User < ApplicationRecord
  has_secure_password

  has_many :publications, dependent: :nullify

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
