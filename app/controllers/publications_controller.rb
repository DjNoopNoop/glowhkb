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
    @publication = Publication.new(publication_params)
    apply_tag_creatable_associations(@publication)

    if @publication.save
      redirect_to @publication, notice: "Publication created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    puts "*"*100
    puts publication_params
    puts "-"*100
    @publication.assign_attributes(publication_params)
    apply_tag_creatable_associations(@publication)

    if @publication.save
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
end
