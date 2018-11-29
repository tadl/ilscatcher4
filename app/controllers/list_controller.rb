class ListController < ApplicationController
  respond_to :html, :json, :js
  before_action :check_for_token, except: [:view_list]

  def lists
    if @user
      @lists = get_lists_and_set_cookie(@user)
    else
      @lists = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.html
      format.json {render :json => @lists}
    end
  end

  def view_list
    if params[:list_id]
      if params[:page]
        page = params[:page]
      else
        page = 0
      end
      if @user
        list_hash = @user.TEMP_view_list(@user.token, params[:list_id], page)
      else
        @user = User.new
        list_hash = @user.TEMP_view_list(nil, params[:list_id], page)
      end
      @list = list_hash['list']
      @items = list_hash['items']
    else
      @list = {:error => 'missing parameters'}
      @items = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.html
      format.json {render :json =>{ list: @list, items: @items}}
      format.js
    end
  end

  def create_list
    if @user && params[:name] && params[:shared]
      list = List.new
      @message = list.create(@user.token, params)
      @lists = get_lists_and_set_cookie(@user)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.html
      format.json {render :json =>{ message: @message, lists: @lists}}
      format.js
    end
  end

  def edit_list
    if @user && params[:list_id] && params[:offset]
      list = List.new
      @message = list.edit(@user.token, params)
      @lists = get_lists_and_set_cookie(@user)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json =>{ message: @message, lists: @lists}}
    end
  end

  #share param can equal show or hide
  def share_list
    if @user && params[:list_id] && params[:offset] && params[:share]
      list = List.new
      @message = list.share(@user.token, params)
      @lists = get_lists_and_set_cookie(@user)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json =>{ message: @message, lists: @lists}}
    end
  end

  def make_default_list
    if @user && params[:list_id]
      list = List.new
      @message = list.make_default(@user.token, params[:list_id])
      @lists = get_lists_and_set_cookie(@user)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.html
      format.json {render :json =>{ message: @message, lists: @lists}}
      format.js
    end
  end

  def destroy_list
    if @user && params[:list_id]
      list = List.new
      @message = list.destroy(@user.token, params[:list_id])
      @lists = get_lists_and_set_cookie(@user)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.html
      format.json {render :json =>{ message: @message, lists: @lists}}
      format.js
    end
  end

  def add_note_to_list
    if @user && params[:list_id] && params[:list_item_id] && params[:note]
      list = List.new
      @message = list.add_note(@user.token, params)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.html
      format.json {render :json =>{ message: @message}}
      format.js
    end
  end

  # not sending a note param or sending it as a blank string will delete the note
  def edit_note
    if @user && params[:list_id] && params[:note_id] 
      list = List.new
      @message = list.edit_note(@user.token, params)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.html
      format.json {render :json =>{ message: @message}}
      format.js
    end
  end

  def add_item
    if @user && params[:list_id] && params[:record_id] 
      list = List.new
      @message = list.add_item(@user.token, params)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.html
      format.json {render :json =>{ message: @message}}
      format.js
    end
  end

  def remove_item
    if @user && params[:list_id] && params[:list_item_id] 
      list = List.new
      @message = list.remove_item(@user.token, params)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.html
      format.json {render :json =>{ message: @message}}
      format.js
    end
  end

  private

  def get_lists_and_set_cookie(user)
    lists = user.TEMP_get_lists
    cookies[:lists] = {:value => lists.to_json, :expires => 1.hour.from_now.utc}
    return lists
  end

end
