class SearchController < ApplicationController
  before_action :ensure_json_request
  def search
    if !params[:query]
      params[:query] = ''
    end
    if !params[:view]
      if cookies[:layout]
        params[:view] = cookies[:layout]
      else
        params[:view] = Settings.default_layout
      end
    else
      cookies[:layout] = {:value => params[:view]}
    end 
    if params[:type] == "shelving_location"
      Settings.lists.each do |list|
        list[:searches].each do |search|
          search[:params].each do |k,v|
            if v == params[:query]
              @search_title = search[:display_name]
            end
          end
        end
      end
    end
  	@search = Search.new(allowed_params)
    unless params[:new_search] == 'true'
      @search.get_results
    end
    respond_to do |format|
      format.html
      format.json {render :json => @search}
      format.js
    end
  end

  private
  def ensure_json_request
    return if request.format.json?
    head :not_acceptable
  end

  def allowed_params
    params.permit(:query, :type, :sort, :fmt, :location, :page, :size, :limit_available, :view,
                  :ids, :audiences, :limit_physical, subjects: [], authors: [], genres: [], series: [])
  end
end
