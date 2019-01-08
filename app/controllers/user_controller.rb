class UserController < ApplicationController
  respond_to :html, :json, :js
  before_action :check_for_token, except: [:login, :login_and_place_hold, :sign_in, :missing_token, :request_password_reset, :submit_password_reset]

  def login
    if cookies[:login] || params[:token] || (params[:username] && (params[:password] || params[:md5password]))
      @user = User.new

      if params[:password] && (params[:password].length <= 4)
        @user.temp_password = true
      end

      if cookies[:login] && (!params[:token] || !params[:username])
        params[:token] = cookies[:login]
      end

      @user.login(params)

      if @user.error == nil
        cookies[:login] = {:value => @user.token, :expires => 1.hour.from_now.utc}
        cookies[:user] = {:value => @user.to_json, :expires => 1.hour.from_now.utc}
        @from_action = params[:from_action]
        @target_hold = params[:target_hold]
      else
        cookies.delete :login
        cookies.delete :user
        cookies.delete :lists
      end

    else
      @user = {'error'=> 'missing parameters'}
    end

    respond_to do |format|
      format.json {render :json => @user}
      format.js
    end

  end

  def login_and_place_hold
    @target_hold = params[:target_hold]
    @from_action = params[:from_action]
    respond_to do |format|
      format.js
    end
  end

  def sign_in
    @from_action = params[:from_action]
    @message = ' to view your ' + params[:from_action]
    respond_to do |format|
      format.html
    end
  end


  def logout
    if @user
      key_name = 'lists_' + @user.token
      Rails.cache.delete('key_name')
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

  def all_account
    #invoking these classes before calling on them again in parallel avoids weird crashes with no performance impact
    if @user
    prep_job = Scraper.new
    prep_search = Search.new
    prep_hold = Hold.new
    prep_checkout = Checkout.new
    prep_list = List.new
      Parallel.each([1,2,3,4,5,6,7], in_threads: 7){|task|
        case task
          when 1
            @preferences = @user.TEMP_get_preferences
          when 2
            @checkouts = @user.TEMP_get_checkouts
          when 3
            @holds = @user.TEMP_get_holds(false)
          when 4
            basic_info_and_cookies(@user)
          when 5
            request_fines = @user.TEMP_fines
            @fines = request_fines['fines']
            @fees = request_fines['fees']
          when 6
            @payments = @user.TEMP_payments
          when 7
            @lists = @user.TEMP_get_lists
          else
        end
      }
    end 
    respond_to do |format|
      format.json {render :json =>{:user => @user, :checkouts => @checkouts, :preferences => @preferences, :holds => @holds, :fines => @fines, :fees => @fees, :payments => @payments, :lists => @lists}}
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
      @checkouts = renew_request[2]
      @message = renew_request[0]
      @errors = renew_request[1]
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
    else
      @checkouts = {:error => 'missing parameters'}
    end

    respond_to do |format|
      format.html
      format.json {render :json =>{:user => @user, :checkouts => @checkouts, :page => @page,
                  :more_results => @more_results}}
      format.js
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
    @hold = Hold.new
    if @user && params[:id]
      @hold.id = params[:id]
      @hold = @hold.TEMP_place_hold(@user.token, params[:force])
      basic_info_and_cookies(@user)
    else
      @hold.error = 'missing parameters'
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
      format.js
      format.json {render :json =>{:user => @user, :holds => @holds}}
    end

  end

  def change_hold_pickup
    if @user && params[:hold_id] && params[:hold_status] && params[:pickup_location]
      #what follows is neccessary but doesn't make any sense. screen scraping. shrug
      if params[:hold_status].blank? || params[:hold_status] == 'Active'
        params[:hold_status] = 'Activate' 
      end
      if params[:hold_status] == 'Suspended'
        params[:hold_status] = 'Active'
      end 
      @hold = @user.TEMP_change_hold_pickup(params[:hold_id], params[:hold_status], params[:pickup_location])
    else
      @hold = {:error => 'missing parameters'}
    end

    respond_to do |format|
      format.js
      format.json {render :json => @hold }
    end

  end

# FINES
  def fines
    if @user
      request_fines = @user.TEMP_fines
      @fines = request_fines['fines']
      @fees = request_fines['fees']
    else
      @fines = {:error => 'missing parameters'}
      @fees = {:error => 'missing parameters'}
    end

    respond_to do |format|
      format.html
      format.json {render :json =>{:fines => @fines, :fees => @fees}}
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
      #invoking this class before calling on it again in parallel avoids weird crashes with no performance impact
      prep_job = Scraper.new
      Parallel.each([1,2], in_threads: 2){|task|
        case task
          when 1
            @preferences = @user.TEMP_get_preferences
          when 2
            basic_info_and_cookies(@user)
          else
        end
      } 
    end
    respond_to do |format|
      format.html
      format.json {render :json =>{:user => @user, :preferences => @preferences}}
    end

  end

  def update_preferences
    if @user
      @update_preferences = @user.update_preferences(params)
      Parallel.each([1,2], in_threads: 2){|task|
        case task
          when 1
            @preferences = @user.TEMP_get_preferences
          when 2
            basic_info_and_cookies(@user)
          else
        end
      }  
    end
    respond_to do |format|
      format.json {render :json =>{:user => @user, :messages => @update_preferences, :preferences => @preferences}}
      format.js
    end
  end



  def missing_token
    @message = {:error=> 'not logged in or invalid token'}

    respond_to do |format|
      format.json {render :json => @message}
    end

  end

#RESET PASSWORD

  def request_password_reset
    respond_to do |format|
      format.js
      format.html
    end
  end

  #user could be a username or card number
  def submit_password_reset
    if !params[:user].blank?
      user = User.new
      @message = user.submit_password_reset(params[:user])
    else
      @message = {:error=> 'did not pass a username or card #'}
    end
    respond_to do |format|
      format.json {render :json => @message}
      format.js
    end
  end

  def save_account_preferences
    if @user
      @preferences = @user.TEMP_get_preferences
      basic_info_and_cookies(@user)
    end
    respond_to do |format|
      format.json {render :json => @message}
      format.js
    end
  end 

  def change_temp_password
    if @user
      @change_password_request = @user.change_temp_password(params)
    end
    respond_to do |format|
      format.js
    end
  end



private

  def basic_info_and_cookies(user)
    user.TEMP_get_basic_info
    cookies[:login] = {:value => @user.token, :expires => 1.hour.from_now.utc}
    cookies[:user] = {:value => @user.to_json, :expires => 1.hour.from_now.utc}
  end

end
