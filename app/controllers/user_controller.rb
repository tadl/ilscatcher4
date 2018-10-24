class UserController < ApplicationController
  respond_to :html, :json, :js
  
  def login
    if params[:token] || (params[:username] && (params[:password] || params[:md5password]))
      @user = User.new
      @user.login(params)
      if @user.error == nil
        @user.TEMP_get_basic_info
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

  def checkouts
    if params[:token]
      @user = User.new
      @checkouts = @user.TEMP_get_checkouts(params[:token])
    else
      @checkouts = {'error'=> 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json => @checkouts}
    end
  end

end