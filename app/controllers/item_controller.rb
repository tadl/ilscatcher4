class ItemController < ApplicationController
  respond_to :html, :json, :js

  def details
    search = Search.new(query: params[:id], type: 'record_id')
    search.get_results
    @item = search.results[0]
    location_copies = 0

    if params[:order]
      @item.result_order = params[:order].to_i
    end

    if params[:location]
      @item.search_location = params[:location].to_i
      if @item.electronic == false
        @item.availability['by_location'].select{|h| h['code'].to_i == params[:location].to_i}.each do |l|
          location_copies = location_copies + l['copies_available']
        end
      end

    end

    @item.search_location_copies = location_copies

    respond_to do |format|
      format.html
      format.json {render :json => @item}
      format.js
    end

  end

  def marc_record
    item = Item.new
    item.id = params[:id]
    @marc = item.marc_format
    respond_to do |format|
      format.json {render :json => @marc}
      format.js
    end
  end

  def youtube_trailer
    @id = params[:id]
    respond_to do |format|
      format.html {render :layout => 'frame'}
    end
  end

end
