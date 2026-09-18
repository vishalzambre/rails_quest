module Admin
  class SessionsController < ApplicationController
    layout "admin"
    rate_limit to: 8, within: 1.minute, by: -> { request.remote_ip }, only: :create

    def new
      redirect_to admin_root_path if admin_signed_in?
    end

    def create
      if credentials_match?
        session[:admin] = true
        redirect_to admin_root_path, notice: "Welcome back."
      else
        flash.now[:alert] = "Invalid admin credentials."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:admin)
      redirect_to admin_login_path, notice: "Signed out."
    end

    private

    def credentials_match?
      username = ENV.fetch("ADMIN_USERNAME", "admin")
      password = ENV.fetch("ADMIN_PASSWORD", "changeme")
      hashed = ->(value) { Digest::SHA256.hexdigest(value.to_s) }
      ActiveSupport::SecurityUtils.secure_compare(hashed.call(params[:username]), hashed.call(username)) &&
        ActiveSupport::SecurityUtils.secure_compare(hashed.call(params[:password]), hashed.call(password))
    end
  end
end
