class ListController < ApplicationController
  respond_to :html, :json, :js
  before_action :check_for_token, except: [:view_list]

  def lists
    if @user
      @lists = get_lists_and_set_cache(@user)
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
      if params[:token] || cookies[:login]
        @user = User.new
        @user.token = params[:token] || cookies[:login]
      else
        @user = nil
      end
      if @user
        @list = @user.TEMP_view_list(@user.token, params[:list_id], page, params[:sort])
      else
        @user = User.new
        @list = @user.TEMP_view_list(nil, params[:list_id], page, params[:sort])
      end
      if @user.token
        key_name = 'lists_' + @user.token
        @mylists = Rails.cache.fetch(key_name)
        if @mylists.size > 0 
          @mylists.each do |l|
            if l.list_id == params[:list_id]
              @my_list = true
            end
          end
        end
      else
        @my_list = false
      end
    else
      @list = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.html
      format.json {render :json =>{ list: @list}}
      format.js
    end
  end

  # shared param can be no or yes
  def create_list
    if @user && params[:name] && params[:shared]
      list = List.new
      @message = list.create(@user.token, params)
      @lists = get_lists_and_set_cache(@user)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json =>{ message: @message, lists: @lists}}
    end
  end

  def edit_list
    if @user && params[:list_id] && params[:offset]
      list = List.new
      @message = list.edit(@user.token, params)
      @lists = get_lists_and_set_cache(@user)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json =>{ message: @message, lists: @lists}}
    end
  end

  # share param can be show or hide
  def share_list
    if @user && params[:list_id] && params[:offset] && params[:share]
      list = List.new
      @message = list.share(@user.token, params)
      @lists = get_lists_and_set_cache(@user)
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
      @lists = get_lists_and_set_cache(@user)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json =>{ message: @message, lists: @lists}}
    end
  end

  def destroy_list
    if @user && params[:list_id]
      list = List.new
      @message = list.destroy(@user.token, params[:list_id])
      @lists = get_lists_and_set_cache(@user)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json =>{ message: @message, lists: @lists}}
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
      format.json {render :json =>{ message: @message}}
    end
  end

  # not sending a note param or sending it as a blank string will delete the note
  # not sending the param is apparently an error.
  def edit_note
    if @user && params[:list_id] && params[:note_id] 
      list = List.new
      @message = list.edit_note(@user.token, params)
    else
      @message = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json =>{ message: @message}}
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
      format.json {render :json =>{ message: @message}}
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
      format.json {render :json =>{ message: @message}}
    end
  end

  private

  def get_lists_and_set_cache(user)
    lists = user.TEMP_get_lists
    key_name = 'lists_' + @user.token
    Rails.cache.write(key_name, lists)
    return lists
  end

end
