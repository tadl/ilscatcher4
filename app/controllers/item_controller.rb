class ItemController < ApplicationController
  respond_to :html, :json, :js
  def details
    if request.format == 'js' && params[:from_slider] != 'true'
      @item = Item.new(allowed_params)
      if @item.holdings != nil
        @item.holdings = @item.holdings.values
      else
        @item.holdings = []
      end
    else
      search = Search.new(query: params[:id], type: 'record_id')
      search.get_results
      @item = search.results[0]
    end
    respond_to do |format|
      format.html
      format.json {render :json => @item}
      format.js
    end
  end

  private

  def allowed_params
    params.permit(:links, :abstract, :publisher_location, :create_date, :isbn, 
                :corpauthor, :electronic, :id, :physical_description, :series, :availability,
                :title, :title_alt, :fiction, :source, :title_display, :abstract_array,
                :contents, :holdable, :title_nonfiling, :contents_array, :edit_date,
                :type_of_resource, :sort_year, :publisher, :title_short, :author, :hold_count,
                :author_other, :record_year, isbn: [], series: [], attrs: {},
                genres: [], holdings: {}, subjects: [], availability: {}, abstract_array: [],
                contents_array: [], author_other: [], title_alt: [], eresource_link:)
  end
end
