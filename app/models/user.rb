class User
  include ActiveModel::Model
  require 'net/http'
  require 'digest/md5'
  attr_accessor :username, :error, :token, :hold_self_alias, :first_name, :last_name, 
                :card, :cards, :email, :message, :full_name, :checkouts, :holds, :holds_ready,
                :fine, :pickup_library, :default_search, :overdue 

  URI = URI.parse('https://' + Settings.evergreen_server + "/osrf-gateway-v1")

  def login(params = '' )
    if params[:token]
      self.token = params[:token]
    elsif params[:password] || params[:md5password]
      login_params = Hash.new
      self.username = params[:username]
      if username_or_barcode == 'username'
        login_params['username'] = params[:username]
      else
        login_params['barcode'] = params[:username]
      end
      if params[:md5password]
        login_params['password'] = params[:md5password]
      else
        login_params['password'] = Digest::MD5.hexdigest(params[:password])
      end
      authenticate(login_params)
    end
    if self.error == nil
      TEMP_get_basic_info()
    end
  end

  def TEMP_get_basic_info
    scraper = Scraper.new
    user_hash = scraper.user_basic_info(self.token)
    if user_hash.to_s != 'error'
      user_hash.each {|k, v| self.send("#{k}=", v)} 
    else
      self.error = 'error: unable to fetch basic info'
    end
  end


  def TEMP_get_checkouts
    scraper = Scraper.new
    checkouts_hash = scraper.user_get_checkouts(self.token)
    if checkouts_hash != 'error'
      return checkouts_hash
    else
      return {:error => 'unable to fetch checkouts'}
    end
  end

  def TEMP_renew_checkouts(checkout_ids)
    scraper = Scraper.new
    renew_response = scraper.user_renew_checkouts(self. token, checkout_ids)
    if renew_response != error
      return renew_response
    else
      return renew_response[:message] = {:error => 'unable to renew checkouts'}
    end
  end

  def TEMP_get_holds
    scraper = Scraper.new
    holds_hash = scraper.user_get_holds(self.token)
    if holds_hash != 'error'
      return holds_hash
    else
      return {:error => 'unable to fetch holds'}
    end
  end

  def TEMP_get_preferences
    scraper = Scraper.new
    preferences_hash = scraper.user_get_preferences(self.token)
    if preferences_hash != 'error'
      return preferences_hash
    else
      return {:error => 'unable to fetch preferences'}
    end
  end

  # Not using this right now because it currently doesn't get us all the data we need
  def get_basic_info
    http = Net::HTTP.new(URI.host, URI.port)
    http.use_ssl = true
    request_seed = Net::HTTP::Post.new(URI.request_uri)
    request_params = {}
    request_params['authtoken'] = token
    request_seed.set_form_data({
      "service" => "open-ils.auth",
      "method" => "open-ils.auth.session.retrieve",
      "param" => '"' + self.token + '"'
    })
    response = http.request(request_seed)
    if response.code == '200'
      j_content = JSON.parse(response.body)
      if j_content['payload'][0]["textcode"] != "NO_SESSION"
        self.melcat_id = j_content['payload'][0]['__p'][47]
        self.username = j_content['payload'][0]['__p'][47]
        self.hold_self_alias = j_content['payload'][0]['__p'][48]
        self.card_number = j_content['payload'][0]['__p'][31]
        self.first_name = j_content['payload'][0]['__p'][26]
        self.last_name = j_content['payload'][0]['__p'][25]
        self.email = j_content['payload'][0]['__p'][22]
      else
        self.username = ''
        self.token = ''
        self.error = 'error: session expired or did not exisit'
      end
    else
      self.error = 'error: could not complete request'
    end
  end


  def logout
    http = Net::HTTP.new(URI.host, URI.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(URI.request_uri)
    request.set_form_data({
        "service" => "open-ils.auth",
        "method" => "open-ils.auth.session.delete",
        "param" => '"' + self.token + '"'
    })
    response = http.request(request)
    if response.code && response.code == '200'
      self.message = "success: Logout success"
    else
      self.error = "error: Logout failed"
    end
  end

private
  def username_or_barcode
    if (self.username =~ /^TADL\d{7,8}$|^90\d{5}$|^91111\d{9}$|^[a-zA-Z]\d{10}/)
      return 'barcode'
    else
      return 'username'
    end
  end

  def authenticate(login_params)
    http = Net::HTTP.new(URI.host, URI.port)
    http.use_ssl = true
    request_seed = Net::HTTP::Post.new(URI.request_uri)
    request_seed.set_form_data({
      "service" => "open-ils.auth",
      "method" => "open-ils.auth.authenticate.init",
      "param" => '"' + self.username + '"'
    })
    response = http.request(request_seed)
    if response.code == '200'
      seed = JSON.parse(response.body)['payload'][0]
    else
     self.error = 'error could not complete auth init request'
    end
    login_params['type'] = 'opac'
    login_params['password'] = Digest::MD5.hexdigest(seed + login_params['password'])
    http = Net::HTTP.new(URI.host, URI.port)
    http.use_ssl = true
    request_complete = Net::HTTP::Post.new(URI.request_uri)
    request_complete.set_form_data({
      "method" => "open-ils.auth.authenticate.complete",
      "service" => "open-ils.auth",
      "param" => JSON.generate(login_params)
    })
    response = http.request(request_complete)
    if response.code == '200'
      j_content = JSON.parse(response.body)
      if j_content['status'] == 200
        if j_content['payload'][0]['ilsevent'] == 0
          self.token = j_content['payload'][0]['payload']['authtoken']
        else
          self.username = ""
          self.token = ""
          self.error = 'error: bad username or password'
        end
      else
        self.error = 'bad token'
      end
    else
      self.error = 'error: could not complete auth complete request' 
    end
  end
end