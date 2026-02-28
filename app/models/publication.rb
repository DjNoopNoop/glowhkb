class Publication < ApplicationRecord
  include TagCreatableAssociations

  belongs_to :submission, optional: true
  belongs_to :geographic_location, optional: true
  belongs_to :user, optional: true

  # Prefer an explicitly assigned user (via `user_id`) but fall back to the
  # linked submission's user when present. This keeps existing callers that
  # expect `publication.user` working whether or not a `user_id` is stored.
  def user
    super.presence || submission&.user
  end

  validates :title, presence: true, uniqueness: true

  has_and_belongs_to_many :air_pollutants, join_table: 'pub_air_pollutants'
  has_and_belongs_to_many :weather_parameters, join_table: 'pub_weather_parameters'
  has_and_belongs_to_many :medical_conditions, join_table: 'pub_medical_conditions'
  has_and_belongs_to_many :statistical_methods, join_table: 'pub_statistical_methods'

  def user_email
    user&.email
  end

  # Declare which HABTM collections are “tag creatable”
  tag_creatable_habtm :air_pollutants, param_key: :air_pollutant_ids
  tag_creatable_habtm :weather_parameters, param_key: :weather_parameter_ids
  tag_creatable_habtm :medical_conditions, param_key: :medical_condition_ids
  tag_creatable_habtm :statistical_methods, param_key: :statistical_method_ids
end
