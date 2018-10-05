class SearchController < ApplicationController
  respond_to :html, :json, :js
  def search
    if !params[:query]
      params[:query] = ''
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
    params.permit(:query, :type, :sort, :fmt, :location, :page, :limit_available, 
                  :limit_physical, subjects: [], authors: [], genres: [], series: [])
  end
end
