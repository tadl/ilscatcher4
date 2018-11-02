class UserController < ApplicationController
  respond_to :html, :json, :js
  before_action :check_for_token, except: [:login, :missing_token] 
  
  def login
    if cookies[:login] || params[:token] || (params[:username] && (params[:password] || params[:md5password]))
      @user = User.new
      if cookies[:login] && (!params[:token] || !params[:username])
        params[:token] = cookies[:login]
      end
      @user.login(params)
      if @user.error == nil
        cookies[:login] = {:value => @user.token, :expires => 1.hour.from_now.utc}
      else
        cookies.delete :login
      end
    else
      @user = {'error'=> 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json => @user}
    end
  end

  def logout
    if @user
      @user.logout
      cookies.delete :login
      @message = {:success => 'logged out'}
    end
    respond_to do |format|
      format.json {render :json => @message}
    end
  end

  def checkouts
    if @user
      @checkouts = @user.TEMP_get_checkouts
      @user.TEMP_get_basic_info
    end
    respond_to do |format|
      format.json {render :json =>{:user => @user, :checkouts => @checkouts}}
    end
  end

  def renew_checkouts
    if @user && params[:checkout_ids]
      renew_request = @user.TEMP_renew_checkouts(params[:checkout_ids])
      @checkouts = renew_request['checkouts']
      @message = renew_request['message']
      @errors = renew_request['errors']
      @user.TEMP_get_basic_info
    else
      @checkouts = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json =>{:user => @user, :message => @message, :errors => @errors, 
                          :checkouts => @checkouts}}
    end
  end


  def holds
    if @user
      @holds = @user.TEMP_get_holds
      @user.TEMP_get_basic_info
    end
    respond_to do |format|
      format.json {render :json =>{:user => @user, :holds => @holds}}
    end
  end

  def place_hold
    if @user && params[:id]
      @item = Item.new
      @item.id = params[:id]
      @hold = @item.TEMP_place_hold(@user.token, params[:force])
      @user.TEMP_get_basic_info
    else
      @hold = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json =>{:user => @user, :hold => @hold}}
    end
  end

  def preferences
    if @user
      @preferences = @user.TEMP_get_preferences
      @user.TEMP_get_basic_info
    end
    respond_to do |format|
      format.json {render :json =>{:user => @user, :preferences => @preferences}}
    end
  end

  def missing_token
    @message = {:error=> 'not logged in or invalid token'}
    respond_to do |format|
      format.json {render :json => @message}
    end
  end


end