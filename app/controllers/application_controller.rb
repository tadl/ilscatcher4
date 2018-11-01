class ApplicationController < ActionController::Base

  # dummy var for development
  @logged_in = false

  #ensure a token has been passed as a param or present as a cookie
  def check_for_token
    if params[:token]
      @user = User.new
      @user.token = params[:token]
      puts 'got a token as param'
      return @user
    elsif cookies[:login]
      @user = User.new
      @user.token = cookies[:login]
      puts 'got a token from cookie'
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