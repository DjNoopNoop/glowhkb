class SubmissionsController < ApplicationController
  before_action :require_login
  before_action :set_submission, only: %i[show edit update destroy]
  before_action :authorize_user, only: %i[edit update destroy]

  def index
    respond_to do |format|
      format.html { render :index }
      format.json do
        # If DataTables server-side params are present, perform server-side processing
        if params[:draw].present?
          draw = params[:draw].to_i

          base = current_user.submissions
          records_total = base.count

          # Searching
          if params.dig(:search, :value).present?
            q = params[:search][:value].strip
            ilike = "%#{q}%"
            base = base.where("title ILIKE :q OR authors ILIKE :q OR journal ILIKE :q OR CAST(year AS TEXT) ILIKE :q", q: ilike)
          end

          records_filtered = base.count

          # Ordering
          if params[:order].present?
            order_info = params[:order]['0'] || params[:order].values.first
            col_idx = order_info[:column].to_i
            dir = (order_info[:dir] == 'desc') ? 'desc' : 'asc'
            col_name = case col_idx
                       when 0 then 'title'
                       when 1 then 'authors'
                       when 2 then 'journal'
                       when 3 then 'year'
                       when 4 then 'doi'
                       when 5 then 'url'
                       when 6 then 'status'
                       when 7 then 'created_at'
                       when 8 then 'updated_at'
                       else 'created_at'
                       end
            base = base.reorder("#{col_name} #{dir}")
          else
            base = base.order(created_at: :desc)
          end

          start = params[:start].to_i
          length = params[:length].to_i > 0 ? params[:length].to_i : 25
          rows = base.offset(start).limit(length)

          data = rows.map do |s|
            {
              id: s.id,
              title: s.title,
              authors: s.authors,
              journal: s.journal,
              year: s.year,
              doi: s.doi,
              url: s.url,
              status: s.status,
              created_at: s.created_at.iso8601,
              updated_at: s.updated_at.iso8601
            }
          end

          # Server-rendered HTML for action buttons (keeps URLs and attributes in Rails)
          data.each_with_index do |row, i|
            submission = rows[i]
            show_link = view_context.link_to('Show', submission_path(submission), class: 'btn btn-sm btn-outline-secondary me-1')
            edit_link = view_context.link_to('Edit', edit_submission_path(submission), class: 'btn btn-sm btn-outline-primary me-1')
            delete_button = view_context.button_to('Delete', submission_path(submission), method: :delete, data: { turbo_confirm: 'Are you sure?' }, form: { class: 'd-inline' }, class: 'btn btn-sm btn-outline-danger')
            row[:actions_html] = (show_link + edit_link + delete_button).to_s
          end

          render json: { draw: draw, recordsTotal: records_total, recordsFiltered: records_filtered, data: data }
        else
          submissions = current_user.submissions.order(created_at: :desc)
          render json: submissions.as_json(methods: [:user_email], include: [])
        end
      end
    end
  end

  def show; end

  def new
    @submission = current_user.submissions.build
  end

  def create
    @submission = Submission.new(assignment_attrs)
    @submission.user = current_user
    sanitize_geographic_location(@submission)
    apply_tag_creatable_associations(@submission)

    if @submission.save
      redirect_to @submission, notice: "Submission created"
    else
      flash.now[:alert] = "Please fix the errors below."
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @submission.assign_attributes(assignment_attrs)
    sanitize_geographic_location(@submission)
    apply_tag_creatable_associations(@submission)

    if @submission.save
      redirect_to @submission, notice: "Submission updated"
    else
      flash.now[:alert] = "Please fix the errors below."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @submission.destroy
    respond_to do |format|
      format.html { redirect_to submissions_path, notice: "Submission deleted" }
      format.json { head :no_content }
    end
  end

  private

  def set_submission
    @submission = Submission.find(params[:id])
  end

  def authorize_user
    redirect_to submissions_path, alert: "Not authorized" unless @submission.user == current_user
  end

  def submission_params
    params.require(:submission).permit(
      :title, :doi, :url, :authors, :journal, :year,
      :geographic_location_name, :geographic_location_id,
      :status,
      air_pollutant_ids: [],
      weather_parameter_ids: [],
      medical_condition_ids: [],
      statistical_method_ids: []
    )
  end

  def apply_tag_creatable_associations(submission)
    p = params[:submission] || {}

    submission.apply_air_pollutant_ids_with_tag_creation!(p[:air_pollutant_ids])
    submission.apply_weather_parameter_ids_with_tag_creation!(p[:weather_parameter_ids])
    submission.apply_medical_condition_ids_with_tag_creation!(p[:medical_condition_ids])
    submission.apply_statistical_method_ids_with_tag_creation!(p[:statistical_method_ids])
  end

  def sanitize_geographic_location(submission)
    p = params[:submission] || {}

    raw = p[:geographic_location_id].presence || p[:geographic_location_name].presence

    if raw.blank? || raw.to_s == "0"
      submission.geographic_location_id = nil
      return
    end

    if raw.to_s.match?(/\A\d+\z/)
      id = raw.to_i
      submission.geographic_location_id = GeographicLocation.exists?(id) ? id : nil
      return
    end

    name = raw.to_s.strip
    if name.present?
      geo = GeographicLocation.find_or_create_by(name: name)
      submission.geographic_location_id = geo.id
    else
      submission.geographic_location_id = nil
    end
  end

  def habtm_keys
    %i[air_pollutant_ids weather_parameter_ids medical_condition_ids statistical_method_ids]
  end

  def assignment_attrs
    submission_params.except(*habtm_keys)
  end
end
