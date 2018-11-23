class RegistrationController < ApplicationController
  respond_to :html, :json, :js

  def register
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
end