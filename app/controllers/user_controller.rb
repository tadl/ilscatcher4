class UserController < ApplicationController
  respond_to :html, :json, :js
  
  def login
    if params[:token] || (params[:username] && (params[:password] || params[:md5password]))
      @user = User.new(allowed_params)
      @user.login(params)
    else
      @user = {'message'=> 'missing parameters'}
    end
    respond_to do |format|
      format.json {render :json => @user}
    end
  end

  private
  
  def allowed_params
    params.permit(:username)
  end

end