class PublicationsController < ApplicationController
  before_action :set_publication, only: %i[show]

  def index
    @publications = Publication.order(year: :desc)

    respond_to do |format|
      format.html
      format.json do
        draw   = params[:draw].to_i
        start  = params[:start].to_i
        length = params[:length].to_i
        length = 25 if length <= 0

        base             = filtered_publications
        records_total    = Publication.count
        records_filtered = base.count

        sortable_columns = { 0 => 'title', 1 => 'authors', 2 => 'journal', 3 => 'year' }
        order_col  = params.dig(:order, '0', :column).to_i
        order_dir  = params.dig(:order, '0', :dir) == 'asc' ? 'ASC' : 'DESC'
        order_sql  = sortable_columns[order_col] ? "#{sortable_columns[order_col]} #{order_dir}" : 'year DESC'

        pubs = base.order(Arel.sql(order_sql)).offset(start).limit(length)

        render json: {
          draw:            draw,
          recordsTotal:    records_total,
          recordsFiltered: records_filtered,
          data:            pubs.map { |p|
            {
              id:                   p.id,
              title:                p.title,
              authors:              p.authors,
              journal:              p.journal,
              year:                 p.year,
              geographic_location:  p.geographic_location&.name,
              url:                  p.url,
              doi:                  p.doi,
              air_pollutants:       p.air_pollutants.map(&:name),
              medical_conditions:   p.medical_conditions.map(&:name),
              weather_parameters:   p.weather_parameters.map(&:name),
              statistical_methods:  p.statistical_methods.map(&:name)
            }
          }
        }
      end
    end
  end

  private

  def filtered_publications
    scope = Publication.all

    q_term = params[:q].presence || params.dig(:search, :value).presence
    if q_term.present?
      q = "%#{q_term.strip}%"
      scope = scope.where("title ILIKE :q OR authors ILIKE :q OR journal ILIKE :q", q: q)
    end

    %w[geographic_location_ids air_pollutant_ids medical_condition_ids weather_parameter_ids statistical_method_ids].each do |key|
      if params[key].present?
        ids = Array(params[key]).map(&:to_i)
        case key
        when 'geographic_location_ids'
          scope = scope.where(geographic_location_id: ids)
        when 'air_pollutant_ids'
          scope = scope.joins(:air_pollutants).where(air_pollutants: { id: ids })
        when 'medical_condition_ids'
          scope = scope.joins(:medical_conditions).where(medical_conditions: { id: ids })
        when 'weather_parameter_ids'
          scope = scope.joins(:weather_parameters).where(weather_parameters: { id: ids })
        when 'statistical_method_ids'
          scope = scope.joins(:statistical_methods).where(statistical_methods: { id: ids })
        end
      end
    end

    scope.distinct
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
