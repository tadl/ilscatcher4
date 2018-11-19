class ListController < ApplicationController
  respond_to :html, :json, :js
  before_action :check_for_token, except: [:view_list]

  def lists
    if @user
      @lists = @user.TEMP_get_lists
      cookies[:lists] = {:value => @lists.to_json, :expires => 1.hour.from_now.utc}
    else
      @list = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.html
      format.json {render :json => @lists}
    end
  end

  def view_list
    if params[:list_id]
      if @user
        list_hash = @user.TEMP_view_list(@user.token, params[:list_id])
      else
        @user = User.new
        list_hash = @user.TEMP_view_list(nil, params[:list_id])
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
    end
  end

end
