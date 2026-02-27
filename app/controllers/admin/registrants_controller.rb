module Admin
  class RegistrantsController < Admin::ApplicationController
    before_action :set_registrant, only: [:show, :approve, :deny]

    def index
      @registrants = User.pending.order(:email)
      respond_to do |format|
        format.html
        format.json { render json: @registrants.as_json(only: %i[id name email]) }
      end
    end

    def show
    end

    def approve
      begin
        @registrant.activate!
        redirect_to admin_registrants_path, notice: "Registrant approved."
      rescue => e
        redirect_to admin_registrants_path, alert: "Unable to approve registrant."
      end
    end

    def deny
      begin
        @registrant.deny!
        redirect_to admin_registrants_path, notice: "Registrant denied."
      rescue => e
        redirect_to admin_registrants_path, alert: "Unable to deny registrant."
      end
    end

    private

    def set_registrant
      @registrant = User.find(params[:id])
    end
  end
end
