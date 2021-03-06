class ApplicationController < ActionController::Base

	before_action :signed_in, unless: -> { home_controller? || devise_controller? }
	before_action :check_auth, unless: -> { otp_secret_controller? || otp_logout_check? }	
	before_action :configure_permitted_parameters, if: :devise_controller?

	add_flash_types :success

	protected
    def configure_permitted_parameters
		devise_parameter_sanitizer.permit(:sign_up, keys: [:nickname])
		devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_secret])
		devise_parameter_sanitizer.permit(:account_update, keys: [:nickname, :avatar])
	end

	private

	def signed_in
		redirect_to root_path unless user_signed_in? && :devise_controller?
	end

	def otp_logout_check?
		params[:controller] == "sessions" && params[:action] == "destroy"
	end

	def home_controller?
		return true if params[:controller] == "home"
	end

	def otp_secret_controller?
		return true if params[:controller] == "otp_secrets"
	end

	def check_auth
		if user_signed_in? && current_user.otp_required
			redirect_to otp_secrets_login_path
		end
	end
end
