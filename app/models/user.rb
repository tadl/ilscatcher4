class User
  include ActiveModel::Model
  require 'net/http'
  require 'digest/md5'
  attr_accessor :username, :message, :token

  def login(params = '' )
    if params[:token]
      self.message = 'logged in with token'
    elsif params[:password] || params[:md5password]
      login_params = Hash.new
      if username_or_barcode == 'username'
        login_params['username'] = self.username
        self.message = 'logged in with password and username'
      else
        login_params['barcode'] = self.username
        self.message = 'logged in with password and barcode'
      end
      if params[:md5password]
        seed = get_seed
        puts seed.to_s
        if seed != 'error'
          login_params['password'] = Digest::MD5.hexdigest(seed + params[:md5password])
        else
          self.message = 'error generating seed'
          return
        end
      else
        login_params['password'] = params[:password]
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

  def get_seed
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
      return JSON.parse(response.body)['payload'][0]
    else
      return 'error'
    end
  end

  def authenticate(login_params)
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
      puts  JSON.parse(response.body).to_s
      if j_content['status'] == 200
        puts 'pasta'
        if j_content['payload'][0]['ilsevent'] == 0
          puts j_content['payload'][0]['payload']['authtoken']
          return j_content['payload'][0]['payload']['authtoken']
        else
          return 'error 1'
        end
      else
        return 'error 2'
      end
    else
      return 'error 3' 
    end
  end

end