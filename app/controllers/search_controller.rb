class SearchController < ApplicationController
  respond_to :html, :json, :js
  def search
    if !params[:query]
      params[:query] = ''
    end
  	@search = Search.new(allowed_params)
    results = @search.results
    @items = results[0]
    @more_results = results[1]
    @facets = results[2]
    respond_to do |format|
      format.html
      format.json {render :json => {:query => @search.query, :results => @items, :more_results => @more_results, :facets => @facets}}
      format.js
    end
  end

  private

  def allowed_params
    params.permit(:query, :type, :sort, :fmt, :location, :page, :limit_available, subjects: [],
                  authors: [], genres: [], series: [])
  end
end
