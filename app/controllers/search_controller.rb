class SearchController < ApplicationController
  # Simple unified search across a few models using pg_search scopes.
  def index
    q = params[:q].to_s.strip
    return render json: [] if q.blank?

    pubs = Publication.search_by_term(q).limit(10)
    wps = WeatherParameter.search_by_term(q).limit(6)
    aps = AirPollutant.search_by_term(q).limit(6)

    results = []
    pubs.each do |p|
      results << { type: 'Publication', id: p.id, title: p.title, url: publication_path(p) }
    end

    wps.each do |w|
      results << { type: 'WeatherParameter', id: w.id, title: w.name, url: publications_path(weather_parameter_id: w.id) }
    end

    aps.each do |a|
      results << { type: 'AirPollutant', id: a.id, title: a.name, url: publications_path(air_pollutant_id: a.id) }
    end

    render json: results
  end
end
