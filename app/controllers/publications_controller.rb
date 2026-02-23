class PublicationsController < ApplicationController
  before_action :set_publication, only: %i[show edit update destroy]
  before_action :require_login, except: %i[index show]
  before_action :authorize_user, only: %i[edit update destroy]

  def index
    @publications = Publication.order(year: :desc)
  end

  def show; end

  def new
    @publication = current_user.publications.build
  end

  def create
    pub_params = publication_params
    @publication = current_user.publications.build(pub_params.except(:air_pollutant_names, :weather_parameter_names, :medical_condition_names, :statistical_method_names, :geographic_location_name))
    assign_associations_from_params(@publication, pub_params)
    if @publication.save
      redirect_to @publication, notice: "Publication created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    pub_params = publication_params
    assign_associations_from_params(@publication, pub_params)
    if @publication.update(pub_params.except(:air_pollutant_names, :weather_parameter_names, :medical_condition_names, :statistical_method_names, :geographic_location_name))
      redirect_to @publication, notice: "Publication updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @publication.destroy
    redirect_to publications_path, notice: "Publication deleted"
  end

  private

  def set_publication
    @publication = Publication.find(params[:id])
  end

  def authorize_user
    redirect_to publications_path, alert: "Not authorized" unless @publication.user == current_user
  end

  def publication_params
    params.require(:publication).permit(
      :title,
      :authors,
      :journal,
      :year,
      :doi,
      :url,
      :geographic_location_id,
      :geographic_location_name,
      air_pollutant_names: [],
      weather_parameter_names: [],
      medical_condition_names: [],
      statistical_method_names: []
    )
  end

  def assign_associations_from_params(publication, params_hash)
    return unless params_hash

    # Handle geographic location
    if params_hash[:geographic_location_name].present?
      loc = GeographicLocation.find_or_create_by(name: params_hash[:geographic_location_name].strip)
      publication.geographic_location = loc
    elsif params_hash[:geographic_location_id].present?
      publication.geographic_location_id = params_hash[:geographic_location_id]
    end

    # Ensure arrays for associations
    [:air_pollutant_names, :weather_parameter_names, :medical_condition_names, :statistical_method_names].each do |assoc|
      values = params_hash[assoc]
      values = Array(values).reject(&:blank?)
      next if values.empty?
      model = {
        air_pollutant_names: AirPollutant,
        weather_parameter_names: WeatherParameter,
        medical_condition_names: MedicalCondition,
        statistical_method_names: StatisticalMethod
      }[assoc]
      publication.send(assoc.to_s.sub('_names','='), values.map { |n| model.find_or_create_by(name: n.strip) })
    end
  end
end
