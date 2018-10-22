class UserController < ApplicationController
  respond_to :html, :json, :js
  
  def login
    if params[:token] || (params[:username] && (params[:password] || params[:md5password]))
      @user = User.new
      @user.login(params)
      if @user.error == nil
        @user.get_session_info
      end
    else
      @user = {'error'=> 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json => @user}
    end
  end

  def logout
    if params[:token]
      @user = User.new
      @user.logout(params[:token])
    else
      @user = {'error'=> 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json => @user}
    end
  end
end