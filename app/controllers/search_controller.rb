class SearchController < ApplicationController
  respond_to :html, :json, :js
  def search
    if !params[:query]
      params[:query] = ''
    end
    if !params[:view]
      params[:view] = 'list'
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

  def allowed_params
    params.permit(:query, :type, :sort, :fmt, :location, :page, :size, :limit_available, :view,
                  :limit_physical, subjects: [], authors: [], genres: [], series: [])
  end
end
