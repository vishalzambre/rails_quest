module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :require_admin!

    private

    def require_admin!
      return if admin_signed_in?

      redirect_to admin_login_path, alert: "Admin sign-in required."
    end
  end
end
