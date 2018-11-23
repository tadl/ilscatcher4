class ApplicationController < ActionController::Base
  before_action :extend_cookie_life
  # dummy var for development
  @logged_in = false

  #ensure a token has been passed as a param or present as a cookie
  def check_for_token
    if params[:token] || cookies[:login]
      @user = User.new
      @user.token = params[:token] || cookies[:login]
      return @user
    else
      if params[:format] == 'json'
        redirect_to :controller => 'user', :action => 'missing_token', :format => 'json'
      else
        return @message = {:error=> 'not logged in or invalid token'}
      end
    end
  end

  def extend_cookie_life
    if cookies[:login]
      cookies[:login] = {:value => cookies[:login], :expires => 1.hour.from_now.utc}
    end
    if cookies[:user]
      cookies[:user] = {:value => cookies[:user], :expires => 1.hour.from_now.utc}
    end
    if cookies[:list]
      cookies[:list] = {:value => cookies[:list], :expires => 1.hour.from_now.utc}
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