module Admin
  class ApplicationController < ::ApplicationController
    layout "admin"
    before_action :require_admin

    private

    def require_admin
      redirect_to root_path, alert: "Not authorized" unless current_user&.is_admin?
    end
  end
end
