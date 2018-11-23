class Register 
  require 'net/http'
  require 'cgi'
  include ActiveModel::Model


  def validate_and_save(params)
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

  def valid_states 
    [
    "AL",
    "AK",
    "AS",
    "AZ",
    "AR",
    "CA",
    "CO",
    "CT",
    "DE",
    "DC",
    "FL",
    "GA",
    "GU",
    "HI",
    "ID",
    "IL",
    "IN",
    "IA",
    "KS",
    "KY",
    "LA",
    "ME",
    "MD",
    "MA",
    "MI",
    "MN",
    "MS",
    "MO",
    "MT",
    "NE",
    "NV",
    "NH",
    "NJ",
    "NM",
    "NY",
    "NC",
    "ND",
    "MP",
    "OH",
    "OK",
    "OR",
    "PA",
    "PR",
    "RI",
    "SC",
    "SD",
    "TN",
    "TX",
    "UT",
    "VT",
    "VI",
    "VA",
    "WA",
    "WV",
    "WI",
    "WY",    
    ]
  end

end