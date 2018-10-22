class User
  include ActiveModel::Model
  require 'net/http'
  require 'digest/md5'
  attr_accessor :username, :message, :token

  def login(params = '' )
    if params[:token]
      self.token = params[:token]
    elsif params[:password] || params[:md5password]
      login_params = Hash.new
      if username_or_barcode == 'username'
        login_params['username'] = self.username
      else
        login_params['barcode'] = self.username
      end
      if params[:md5password]
        login_params['password'] = params[:md5password]
      else
        login_params['password'] = Digest::MD5.hexdigest(params[:password])
        puts login_params['password']
      end
      self.token = authenticate(login_params)
    end
  end

private
  URI = URI.parse('https://' + Settings.evergreen_server + "/osrf-gateway-v1")
  
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
      return 'error could not complete auth init request'
    end
    login_params['type'] = 'opac'
    login_params['password'] = Digest::MD5.hexdigest(seed + login_params['password'])
    http = Net::HTTP.new(URI.host, URI.port)
    http.use_ssl = true
    request_complete = Net::HTTP::Post.new(URI.request_uri)
    request_complete.set_form_data({
      "service" => "open-ils.auth",
      "method" => "open-ils.auth.authenticate.complete",
      "param" => JSON.generate(login_params)
    })
    response = http.request(request_complete)
    if response.code == '200'
      j_content = JSON.parse(response.body)
      if j_content['status'] == 200
        if j_content['payload'][0]['ilsevent'] == 0
          return j_content['payload'][0]['payload']['authtoken']
        else
          return 'error: bad username or password'
        end
      end
    else
      return 'error: could not complete auth complete request' 
    end
  end

end