class ItemController < ApplicationController
  respond_to :html, :json, :js
  def details
    @item = Item.new(allowed_params)
    respond_to do |format|
      format.html
      format.json 
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
                contents_array: [], author_other: [], title_alt: [])
  end
end