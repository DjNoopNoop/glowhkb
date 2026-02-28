class Submission < ApplicationRecord
  include TagCreatableAssociations

  belongs_to :user, optional: true
  belongs_to :geographic_location, optional: true
  belongs_to :adjudicated_by, class_name: 'User', optional: true

  validates :title, presence: true

  has_and_belongs_to_many :air_pollutants, join_table: 'sub_air_pollutants'
  has_and_belongs_to_many :weather_parameters, join_table: 'sub_weather_parameters'
  has_and_belongs_to_many :medical_conditions, join_table: 'sub_medical_conditions'
  has_and_belongs_to_many :statistical_methods, join_table: 'sub_statistical_methods'

  # Declare which HABTM collections are “tag creatable”
  tag_creatable_habtm :air_pollutants, param_key: :air_pollutant_ids
  tag_creatable_habtm :weather_parameters, param_key: :weather_parameter_ids
  tag_creatable_habtm :medical_conditions, param_key: :medical_condition_ids
  tag_creatable_habtm :statistical_methods, param_key: :statistical_method_ids

  STATUSES = [
    PENDING = 'pending'.freeze,
    APPROVED = 'approved'.freeze,
    DENIED = 'denied'.freeze
  ].freeze

  scope :pending, -> { where(status: PENDING) }
  scope :approved, -> { where(status: APPROVED) }
  scope :denied, -> { where(status: DENIED) }

  def user_email
    user&.email
  end

  def approve!(by_user = nil)
    ApplicationRecord.transaction do
      update!(status: APPROVED, adjudicated_by: by_user, adjudicated_at: Time.current)
      ::CreatePublicationFromSubmission.new(self).call
    end
  end

  def deny!(by_user = nil)
    update!(status: DENIED, adjudicated_by: by_user, adjudicated_at: Time.current)
  end

  def approved?
    status == APPROVED
  end

  def pending?
    status == PENDING
  end

  def denied?
    status == DENIED
  end

  def adjudicated?
    !pending?
  end

  after_initialize :set_default_status_and_user, if: :new_record?

  private

  def set_default_status_and_user
    self[:status] ||= PENDING
  end
end
