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

  def deny!
    update!(status: DENIED)
  end

  # Role predicate helpers
  def is_admin?
    role == ADMINISTRATOR
  end

  def is_adjudicator?
    role == ADJUDICATOR
  end

  def is_contributor?
    role == CONTRIBUTOR
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
