class RegistrationController < ApplicationController
  respond_to :html, :json, :js

  def register
    respond_to do |format|
      format.html
    end
  end

  def submit_registration
    respond_to do |format|
      format.json
      format.js
    end
  end

  def confirmation
    respond_to do |format|
      format.html
    end
  end

end