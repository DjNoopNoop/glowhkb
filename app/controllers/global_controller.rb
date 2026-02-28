class GlobalController < ApplicationController
  def map
    @publications = Publication.joins(:geographic_location)
      scope = Publication.joins(:geographic_location)
                         .where.not(geographic_locations: { latitude: nil, longitude: nil })

      # Apply filters from params (arrays of ids)
      if params[:geographic_location_ids].present?
        scope = scope.where(geographic_location_id: params[:geographic_location_ids])
      end

      if params[:air_pollutant_ids].present?
        scope = scope.joins(:air_pollutants).where(air_pollutants: { id: params[:air_pollutant_ids] })
      end

      if params[:medical_condition_ids].present?
        scope = scope.joins(:medical_conditions).where(medical_conditions: { id: params[:medical_condition_ids] })
      end

      if params[:weather_parameter_ids].present?
        scope = scope.joins(:weather_parameters).where(weather_parameters: { id: params[:weather_parameter_ids] })
      end

      if params[:statistical_method_ids].present?
        scope = scope.joins(:statistical_methods).where(statistical_methods: { id: params[:statistical_method_ids] })
      end

      @publications = scope.select(
        'publications.id',
        'publications.title',
        'publications.authors',
        'publications.year',
        'publications.journal',
        'publications.url',
        'geographic_locations.latitude AS latitude',
        'geographic_locations.longitude AS longitude'
      ).distinct

      # Load filter option lists for the dropdowns
      @geographic_locations = GeographicLocation.order(:name)
      @air_pollutants = AirPollutant.order(:name)
      @medical_conditions = MedicalCondition.order(:name)
      @weather_parameters = WeatherParameter.order(:name)
      @statistical_methods = StatisticalMethod.order(:name)

      respond_to do |format|
        format.html do
          render
        end
        format.json do
          render json: @publications.as_json(only: [:id, :title, :authors, :year, :journal, :url, :latitude, :longitude])
        end
      end
  end

  def search
  end
end