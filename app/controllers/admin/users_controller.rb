module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: %i[show edit update]

    def index
      @users = User.order(:email)
      respond_to do |format|
        format.html
        format.json { render json: @users.as_json(only: %i[id name email role status]) }
      end
    end

    def show; end

    def edit; end

    def update
      permitted = User.attribute_names.map(&:to_sym) - %i[id password password_digest created_at updated_at]
      if @user.update(params.require(:user).permit(permitted))
        redirect_to admin_user_path(@user), notice: "User updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # Destroy action removed - admin users cannot be deleted via the UI

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
