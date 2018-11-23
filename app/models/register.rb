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
    if validate_hash.size == 0
      if save_registration(params) == 'error'
        validate_hash['server'] = 'error'
      end
    end
    return validate_hash
  end

  #TODO add enews letter registration bit
  def save_registration(params)
    random_pass = 4.times.map { (0..9).to_a.sample }.join
    stgu = Hash.new
    stgu['__c'] = 'stgu'
    stgu['__p'] = [
      nil,
      nil,
      nil, 
      1,
      params[:email],
      random_pass,
      nil,
      params[:first_name],
      params[:middle_name],
      params[:last_name],
      params[:phone],
      nil,
      Settings.register_location,
      params[:birth_date]
    ]

    address = [
      nil,
      nil,
      nil,
      params[:street_address],
      nil,
      params[:city],
      nil,
      params[:state],
      'US',
      params[:zip_code]
    ]

    stgma = Hash.new
    stgma['__c'] = 'stgma'
    stgma['__p'] = address

    stgba = Hash.new
    stgba['__c'] = 'stgba'
    stgba['__p'] = address

    stgu_json = stgu.to_json
    stgma_json = stgma.to_json
    stgba_json = stgba.to_json

    register_path = 'https://catalog.tadl.org/osrf-gateway-v1?service=open-ils.actor&method=open-ils.actor.user.stage.create&param='
    register_path << stgu_json.to_s
    register_path << '&param=' + stgma_json.to_s
    register_path << '&param=' + stgba_json.to_s

    uri = URI.parse(register_path)
    response = Net::HTTP.get_response(uri)
    if response.code == '200'
      return JSON.parse(response.body)
    else
      return 'error'
    end
  end

  private

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