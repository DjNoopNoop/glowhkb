class Adjudicate::SubmissionsController < ApplicationController
  before_action :require_adjudicator
  before_action :set_submission, only: %i[show approve deny]

  def index
    respond_to do |format|
      format.html { render :index }
      format.json do
        if params[:draw].present?
          draw = params[:draw].to_i

          base = Submission.pending
          records_total = base.count

          if params.dig(:search, :value).present?
            q = params[:search][:value].strip
            ilike = "%#{q}%"
            base = base.where("title ILIKE :q OR authors ILIKE :q OR journal ILIKE :q OR CAST(year AS TEXT) ILIKE :q", q: ilike)
          end

          records_filtered = base.count

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

          data.each_with_index do |row, i|
            submission = rows[i]
            show_link = view_context.link_to('Show', adjudicate_submission_path(submission), class: 'btn btn-sm btn-outline-secondary me-1')
            row[:actions_html] = (show_link).to_s
          end

          render json: { draw: draw, recordsTotal: records_total, recordsFiltered: records_filtered, data: data }
        else
          submissions = Submission.pending.order(created_at: :desc)
          render json: submissions.as_json(methods: [:user_email], include: [])
        end
      end
    end
  end

  def show; end

  def approve
    @submission.approve!(current_user)
    redirect_to adjudicate_submissions_path, notice: "Submission approved"
  rescue StandardError => e
    redirect_to adjudicate_submissions_path, alert: "Approve failed: #{e.message}"
  end

  def deny
    @submission.deny!(current_user)
    redirect_to adjudicate_submissions_path, notice: "Submission denied"
  rescue StandardError => e
    redirect_to adjudicate_submissions_path, alert: "Deny failed: #{e.message}"
  end

  private

  def set_submission
    @submission = Submission.find(params[:id])
    if @submission.adjudicated?
      redirect_to adjudicate_submissions_path, alert: "Submission already adjudicated"
      return
    end
  end
end
