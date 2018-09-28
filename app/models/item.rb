class Item
  include ActiveModel::Model
  attr_accessor :isbn, :links, :series, :abstract, :publisher_location, :attrs, :create_date,
                :corpauthor, :electronic, :id, :abstract_array, :genres, :physical_description,
                :title, :holdings, :title_alt, :fiction, :source, :subjects, :title_display,
                :contents, :holdable, :title_nonfiling, :contents_array, :edit_date, 
                :type_of_resource, :sort_year, :publisher, :title_short, :author, :hold_count,
                :author_other, :record_year

  def is_available(search)
    # returns bool if item is available at all or a single location depending on the search location param
    available = false
    if self.electronic == true
      available = true
    elsif search.location == Settings.location_default || Settings.location_single == true
      self.holdings.each do |h|
        if h['status'] == "Available" || h['status'] == "Reshelving"
          available = true
        end
      end
    else
      self.holdings.each do |h|
        if (h['status'] == "Available" || h['status'] == "Reshelving") && h['circ_lib'] == search.location_code
           available = true
        end
      end
    end
    return available 
  end

  def availability_report(search)
    
  end



end