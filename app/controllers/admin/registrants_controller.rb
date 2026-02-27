module Admin
  class RegistrantsController < Admin::ApplicationController
    def index
      @registrants = User.where(status: User::PENDING).order(:email)
    end
  end
end
