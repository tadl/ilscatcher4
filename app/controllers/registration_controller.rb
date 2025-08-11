class RegistrationController < ApplicationController
  respond_to :html, :json, :js
  layout ->(controller) { controller.params[:iframe] == "true" ? "frame" : "application" }
  before_action :allow_iframe

  def register
    @iframe = params[:iframe]
    respond_to do |format|
      format.html
    end
  end

  def submit_registration
    register = Register.new
    @invalid_data = register.validate_and_save(params)
    respond_to do |format|
      format.json {render :json =>@invalid_data}
      format.js
    end
  end

  private

  def allow_iframe
    return unless params[:iframe] == 'true'

    # Remove Rails’ default SAMEORIGIN
    response.headers.delete('X-Frame-Options')

    # Build/override CSP with our allowed parents
    # TODO - Make this configurable in the future via setting or environment variable
    allowed = ["'self'", "https://*.tadl.org", "https://tadl.libdiscovery.org"]
    existing = response.headers['Content-Security-Policy'].to_s

    # Drop any existing frame-ancestors directive, then add ours
    without_fa = existing.gsub(/(?:^|;)\s*frame-ancestors [^;]*/i, '')
    new_csp = [without_fa.strip, "frame-ancestors #{allowed.join(' ')}"].reject(&:empty?).join('; ')
    response.headers['Content-Security-Policy'] = new_csp
  end

end