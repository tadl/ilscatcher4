class Item
  include ActiveModel::Model
  attr_accessor :isbn, :links, :series, :abstract, :publisher_location, :attrs, :create_date,
                :corpauthor, :electronic, :id, :abstract_array, :genres, :physical_description,
                :title, :holdings, :title_alt, :fiction, :source, :subjects, :title_display,
                :contents, :holdable, :title_nonfiling, :contents_array, :edit_date, :search_location,
                :type_of_resource, :sort_year, :publisher, :title_short, :author, :hold_count,
                :author_other, :record_year, :availability, :attrs, :eresource_link, :result_order,
                :search_view, :search_location_copies, :search_code, :author_brief, :author_full,
                :bib_stauts, :author_fullerform, :bib_status, :author_other_brief, :author_other_full,
                :is_large_print, :score, :audiences, :deleted

  def is_available
    # returns bool if item is available at all or a single location depending on the search location param
    available = false
    if self.electronic == true
      available = true
    elsif self.search_location.nil? || self.search_location == Settings.location_default || Settings.location_single == true
      self.holdings.each do |h|
        if h['status'] == "Available" || h['status'] == "Reshelving"
          available = true
        end
      end
    else
      self.holdings.each do |h|
        if (h['status'] == "Available" || h['status'] == "Reshelving") && h['circ_lib'] == self.search_code
           available = true
        end
      end
    end
    return available
  end

  def check_eresource_link
    if self.links.size >= 1
      self.links.each do |l|
        if (l.include? 'via.tadl.org') || (l.include? 'hoopladigital.com')
          self.electronic = true
          return l
        end
      end
    end
    return nil
  end

  def check_availability
    # takes holdings data and compacts to show availability data
    report = Hash.new
    # if an eresouce return a message that says so
    if self.electronic == true
      report['message'] = "eresource"
    else
      report['copies_all'] = 0
      report['copies_all_available'] = 0
      report['by_location'] = Array.new
      Settings.location_options_minus_all.each do |l|
        location_report = Hash.new
        location_report['code'] = l[1]
        location_report['name'] = l[0]
        location_report['name_compact'] = l[2]
        location_report['copies_total'] = 0
        location_report['copies_available'] = 0
        location_report['shelving_locations'] = Array.new
        self.holdings.to_a.each do |h|
          if h['circ_lib'] == l[2]
            report['copies_all'] += 1
            location_report['copies_total'] += 1
            if h['status'] == "Available" || h['status'] == "Reshelving"
              location_report['copies_available'] += 1
              report['copies_all_available'] += 1
              shelving_hash = Hash.new
              shelving_hash['shelving_location'] = h['location']
              shelving_hash['call_number'] = h['call_number']
              shelving_hash['available_copies'] = 1
              # either add the shelving hash to the array or update the available copy count
              if !location_report['shelving_locations'].any? {|sl| sl['shelving_location'] == h['location'] }
                location_report['shelving_locations'].push(shelving_hash)
              else
                existing_hash = location_report['shelving_locations'].find { |sl| sl['shelving_location'] ==  h['location'] }
                existing_hash['available_copies'] +=1
              end
            end
          end
        end
        #if a location has any copies, avaiable or otherwise, push to report
        if location_report['copies_total'] > 0
          report['by_location'].push(location_report)
        end
      end
    end
    return report
  end

  def TEMP_place_hold(token = '', force = '')
    scraper = Scraper.new
    hold_request = scraper.item_place_hold(token, force, self.id)
    if hold_request != 'error'
      return hold_request
    else
      @hold = Hold.new
      @hold.error = 'unable to place hold'
    end
  end

  def marc_format
    scraper = Scraper.new
    marc_request = scraper.item_marc_format(self.id)
    if marc_request != 'error'
     return marc_request
    else
      return "Error: Something went wrong. Please try again later."
    end 
  end



end