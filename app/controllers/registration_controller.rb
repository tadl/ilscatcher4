class RegistrationController < ApplicationController
  respond_to :html, :json, :js

  def register
    respond_to do |format|
      format.html
    end
  end

  def submit_registration
    if params[:phone]
      params[:phone] = validate_phone(params[:phone])
    end
    if !params[:birth_month].blank? && !params[:birth_day].blank? && !params[:birth_year].blank?
      raw_date = params[:birth_year] + '-' + params[:birth_month] + '-' + params[:birth_day]
      raw_date = raw_date.to_date rescue nil
      if raw_date 
        params[:birth_date] = params[:birth_month] + '-' + params[:birth_day] + '-' + params[:birth_year]
      else
        params[:birth_date] = 'invalid'
      end 
    end
    @invalid_data = validate(params)
    respond_to do |format|
      format.json {render :json =>@invalid_data}
      format.js
    end
  end

  def confirmation
    respond_to do |format|
      format.html
    end
  end

  private

  def validate(params)
    validate_hash = {}
    if params[:first_name].blank?
      validate_hash['first_name'] = 'missing'
    end
    if params[:last_name].blank?
      validate_hash['last_name'] = 'missing'
    end
    if params[:street_address].blank?
      validate_hash['street_address'] = 'missing'
    end
    if params[:city].blank?
      validate_hash['city'] = 'missing'
    end
    if params[:state].blank?
      validate_hash['state'] = 'missing'
    elsif !valid_states.include? params[:state]
      validate_hash['state'] = 'invalid'
    end
    if params[:zip_code].blank?
      validate_hash['zip_code'] = 'missing'
    elsif !params[:zip_code].match?(/^\d{5}(?:[-\s]\d{4})?$/)
      validate_hash['zip_code'] = 'invalid'
    end
    if params[:phone].blank?
      validate_hash['phone'] = 'missing'
    elsif params[:phone] == 'invalid'
      validate_hash['phone'] = 'invalid'
    end
    if !params[:email].blank? && !params[:email].match?(/\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/)
      validate_hash['email'] = 'invalid'
    end
    if params[:birth_date] == 'invalid'
      validate_hash['birth_date'] = 'invalid'
    end
    return validate_hash
  end

  def validate_phone(phone)
    phone = phone.delete('^0-9')
    if phone.length != 10 && phone.length != 11
      return 'invalid'
    elsif phone.length == 11 && phone[0] != '1'
      return 'invalid'
    else
      if phone.length == 11
        phone[0] = ''
      end
      return phone.insert(-8, '-').insert(-5, '-')
    end
  end


end