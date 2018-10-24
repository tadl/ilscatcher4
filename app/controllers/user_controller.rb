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
      @user.token = params[:token]
      @checkouts = @user.TEMP_get_checkouts
      @user.TEMP_get_basic_info
    else
      @checkouts = {'error'=> 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json =>{:user => @user, :checkouts => @checkouts}}
    end
  end

  def holds
    if params[:token]
      @user = User.new
      @user.token = params[:token]
      @holds = @user.TEMP_get_holds
      @user.TEMP_get_basic_info
    else
      @holds = {'error'=> 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json =>{:user => @user, :holds => @holds}}
    end
  end


end