class PublicationsController < ApplicationController
  before_action :set_publication, only: %i[show]

  def index
    @publications = Publication.order(year: :desc)
  end

  def show; end

  private

  def set_publication
    @publication = Publication.find(params[:id])
  end

  def publication_params
    params.require(:publication).permit(
      :title, :doi, :url, :authors, :journal, :year,
      :geographic_location_name, :geographic_location_id,
      air_pollutant_ids: [],
      weather_parameter_ids: [],
      medical_condition_ids: [],
      statistical_method_ids: []
    )
  end

  def apply_tag_creatable_associations(publication)
    p = params[:publication] || {}

    publication.apply_air_pollutant_ids_with_tag_creation!(p[:air_pollutant_ids])
    publication.apply_weather_parameter_ids_with_tag_creation!(p[:weather_parameter_ids])
    publication.apply_medical_condition_ids_with_tag_creation!(p[:medical_condition_ids])
    publication.apply_statistical_method_ids_with_tag_creation!(p[:statistical_method_ids])
  end

  def sanitize_geographic_location(publication)
    p = params[:publication] || {}

    raw = p[:geographic_location_id].presence || p[:geographic_location_name].presence

    # empty or explicit "0" -> unset
    if raw.blank? || raw.to_s == "0"
      publication.geographic_location_id = nil
      return
    end

    # numeric -> use as id if it exists
    if raw.to_s.match?(/\A\d+\z/)
      id = raw.to_i
      publication.geographic_location_id = GeographicLocation.exists?(id) ? id : nil
      return
    end

    # otherwise treat as a name: find or create
    name = raw.to_s.strip
    if name.present?
      geo = GeographicLocation.find_or_create_by(name: name)
      publication.geographic_location_id = geo.id
    else
      publication.geographic_location_id = nil
    end
  end

  def habtm_keys
    %i[air_pollutant_ids weather_parameter_ids medical_condition_ids statistical_method_ids]
  end

  def assignment_attrs
    publication_params.except(*habtm_keys)
  end
end
