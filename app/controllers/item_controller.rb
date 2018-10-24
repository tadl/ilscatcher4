class ItemController < ApplicationController
  respond_to :html, :json, :js
  def details
    search = Search.new(query: params[:id], type: 'record_id')
    search.get_results
    @item = search.results[0]
    if params[:order]
      @item.result_order = params[:order].to_i
    end
    if params[:location]
      @item.search_location = params[:location].to_i
    end
    respond_to do |format|
      format.html
      format.json {render :json => @item}
      format.js
    end

  end


end
