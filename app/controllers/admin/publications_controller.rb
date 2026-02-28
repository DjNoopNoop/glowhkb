module Admin
  class PublicationsController < Admin::ApplicationController
    before_action :set_publication, only: %i[show edit update destroy]

    def index
      @publications = Publication.order(year: :desc)
      respond_to do |format|
        format.html
        format.json do
          render json: @publications.map { |p|
            {
              id: p.id,
              title: p.title,
              year: p.year,
              user_email: p.user&.email
            }
          }
        end
      end
    end

    def new
      @publication = Publication.new
      render :new
    end

    def create
      @publication = Publication.new(assignment_attrs)
      sanitize_geographic_location(@publication)
      apply_tag_creatable_associations(@publication)

      # Admin-created publications are owned by the admin user creating them
      @publication.user = current_user

      if @publication.save
        redirect_to admin_publication_path(@publication), notice: "Publication created"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show; end

    def edit; end

    def update
      @publication.assign_attributes(assignment_attrs)
      sanitize_geographic_location(@publication)
      apply_tag_creatable_associations(@publication)

      # Do not change ownership or link submissions via admin update.

      if @publication.save
        redirect_to admin_publication_path(@publication), notice: "Publication updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @publication.destroy
      respond_to do |format|
        format.html { redirect_to admin_publications_path, notice: "Publication deleted" }
        format.json { head :no_content }
      end
    end

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
      if raw.to_s.match?( /\A\d+\z/ )
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
end
