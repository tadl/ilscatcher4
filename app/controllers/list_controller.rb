class ListController < ApplicationController
  respond_to :html, :json, :js
  before_action :check_for_token, except: [:view_list]

  def lists
    if @user
      @lists = @user.TEMP_get_lists
    else
      @list = {:error => 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json => @lists}
    end
  end

end