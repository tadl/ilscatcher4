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
        cookies[:user] = {:value => @user.to_json, :expires => 1.hour.from_now.utc}
      else
        cookies.delete :login
        cookies.delete :user
      end

    else
      @user = {'error'=> 'missing parameters'}
    end

    respond_to do |format|
      format.json {render :json => @user}
      format.js
    end

  end

  def logout
    if @user
      @user.logout
      cookies.delete :login
      cookies.delete :user
      @message = {:success => 'logged out'}
    end

    respond_to do |format|
      format.json {render :json => @message}
      format.js
    end

  end

#CHECKOUTS
  def checkouts
    if @user
      @checkouts = @user.TEMP_get_checkouts
      basic_info_and_cookies(@user)
    end

    respond_to do |format|
      format.html
      format.json {render :json =>{:user => @user, :checkouts => @checkouts}}
    end

  end

  def renew_checkouts
    if @user && params[:checkout_ids]
      renew_request = @user.TEMP_renew_checkouts(params[:checkout_ids])
      @checkouts = renew_request['checkouts']
      @message = renew_request['message']
      @errors = renew_request['errors']
      basic_info_and_cookies(@user)
    else
      @checkouts = {:error => 'missing parameters'}
    end

    respond_to do |format|
      format.js
      format.json {render :json =>{:user => @user, :message => @message, :errors => @errors,
                          :checkouts => @checkouts}}
    end

  end

  def checkout_history
    if @user
      if params[:page]
        @page = params[:page].to_i
      else
        @page = 0
      end

      checkouts_hash = @user.TEMP_checkout_history(@page)
      @checkouts = checkouts_hash['checkouts']
      @more_results = checkouts_hash['more_results']
      basic_info_and_cookies(@user)
    else
      @checkouts = {:error => 'missing parameters'}
    end

    respond_to do |format|
      format.html
      format.json {render :json =>{:user => @user, :checkouts => @checkouts, :page => @page,
                  :more_results => @more_results}}
    end

  end

#HOLDS
  def holds
    if @user
      @holds = @user.TEMP_get_holds(params[:ready])
      basic_info_and_cookies(@user)
    end

    respond_to do |format|
      format.html
      format.json {render :json =>{:user => @user, :holds => @holds}}
    end

  end

  def place_hold
    if @user && params[:id]
      @item = Item.new
      @item.id = params[:id]
      @hold = @item.TEMP_place_hold(@user.token, params[:force])
      basic_info_and_cookies(@user)
    else
      @hold = {:error => 'missing parameters'}
    end

    respond_to do |format|
      format.js
      format.json {render :json =>{:user => @user, :hold => @hold}}
    end

  end

  #valid task params are activate, suspend and cancel
  def manage_hold
    if @user && params[:hold_id] && params[:task]
      @holds = @user.TEMP_manage_hold(params[:hold_id], params[:task])
      basic_info_and_cookies(@user)
    else
      @holds = {:error => 'missing parameters'}
    end

    respond_to do |format|
      format.json {render :json =>{:user => @user, :holds => @holds}}
    end

  end

  def change_hold_pickup
    if @user && params[:hold_id] && params[:hold_status] && params[:pickup_location]
      @hold = @user.TEMP_change_hold_pickup(params[:hold_id], params[:hold_status], params[:pickup_location])
    else
      @hold = {:error => 'missing parameters'}
    end

    respond_to do |format|
      format.json {render :json => @hold }
    end

  end

# FINES
  def fines
    if @user
      @fines = @user.TEMP_fines
    else
      @fines = {:error => 'missing parameters'}
    end

    respond_to do |format|
      format.html
      format.json {render :json => @fines}
    end

  end

  def payments
    if @user
      @payments = @user.TEMP_payments
    else
      @payments = {:error => 'missing parameters'}
    end

    respond_to do |format|
      format.html
      format.json {render :json => @payments}
    end

  end

  def preferences
    if @user
      @preferences = @user.TEMP_get_preferences
      basic_info_and_cookies(@user)
    end

    respond_to do |format|
      format.html
      format.json {render :json =>{:user => @user, :preferences => @preferences}}
    end

  end

  def missing_token
    @message = {:error=> 'not logged in or invalid token'}

    respond_to do |format|
      format.json {render :json => @message}
    end

  end

private

  def basic_info_and_cookies(user)
    user.TEMP_get_basic_info
    cookies[:login] = {:value => @user.token, :expires => 1.hour.from_now.utc}
    cookies[:user] = {:value => @user.to_json, :expires => 1.hour.from_now.utc}
  end

end
