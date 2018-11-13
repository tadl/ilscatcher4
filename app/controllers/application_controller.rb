class ApplicationController < ActionController::Base
  # dummy var for development
  @logged_in = false

  #ensure a token has been passed as a param or present as a cookie
  def check_for_token
    if params[:token] || cookies[:login]
      @user = User.new
      @user.token = params[:token] || cookies[:login]
      cookies[:login] = {:value => @user.token, :expires => 1.hour.from_now.utc}
      return @user
    else
      if params[:format] == 'json'
        redirect_to :controller => 'user', :action => 'missing_token', :format => 'json'
      else
        return @message = {:error=> 'not logged in or invalid token'}
      end
    end
  end
end