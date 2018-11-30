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
        redirect_to :controller => 'user', :action => 'sign_in', :from_action => params[:action]
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
    if cookies[:lists]
      cookies[:lists] = {:value => cookies[:lists], :expires => 1.hour.from_now.utc}
    end
  end

end
