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
    @publication = current_user.publications.build(publication_params)
    if @publication.save
      redirect_to @publication, notice: "Publication created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @publication.update(publication_params)
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
    params.require(:publication).permit(:title, :authors, :institutions, :journal, :year, :volume, :pages, :data_source, :population, :time_frame, :diagnosis, :emergency_departments, :exposure_periods, :country_region, :subject_type, :disease_studied, :demographics, :race_ethnicity, :statistical_methods, :pollution_parameters, :weather_parameters, :odds_ratio, :risk_ratio)
  end
end
