class AutocompleteController < ApplicationController
  def search
    resource = params[:resource]
    q = params[:q].to_s
    model = case resource
            when 'air_pollutants' then AirPollutant
            when 'weather_parameters' then WeatherParameter
            when 'medical_conditions' then MedicalCondition
            when 'statistical_methods' then StatisticalMethod
            when 'geographic_locations' then GeographicLocation
            else
              return render json: []
            end

    results = model.where('name ILIKE ?', "%#{q}%").limit(10).map do |r|
      h = { id: r.id, name: r.name }
      if resource == 'geographic_locations'
        h[:latitude] = r.latitude
        h[:longitude] = r.longitude
      end
      h
    end

    render json: results
  end
end
