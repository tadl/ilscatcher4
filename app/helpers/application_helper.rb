module ApplicationHelper

  def location_map(id, type = 'short') # type can be 'short' (TADL-WOOD) [2] or 'long' (Traverse City) [0]
    output = ''
    Settings.location_options.each do |location_array|
      if location_array[1].to_s == id.to_s
        output = (type == 'short') ? location_array[2] : location_array[0]
      end
    end
    return output
  end

  def location_super_long_map(super_long_name, type = 'code') #type can be 'code' (22) or long 'long' (Traverse City)
      output = ''
      Settings.location_options.each do |location_array|
      if location_array[3] == super_long_name
        output = (type == 'code') ? location_array[1] : location_array[0]
      end
    end
    return output
  end
  
  def location_short_to_long(short_code)
    Settings.location_options.each do |l|
      if l[2] == short_code
        return l[0]
      end
    end 
    #if no match (which shouldn't happen but may return short_code)
    return short_code
  end


  def check_selected(current, option)
    if current == option
      return 'selected'
    end
  end

  def search_link_builder(type = '', search = '', facet = '')
    url = '/search?query=' + search.query if search.query
    url += '&type=' + search.type if search.type
    url += '&fmt=' + search.fmt if search.fmt
    url += '&sort=' + search.sort if search.sort
    url += '&location=' + search.location if search.location
    url += '&limit_physical=' + search.limit_physical if search.limit_physical
    url += '&limit_available=' + search.limit_available if search.limit_available
    url += '&view=' + search.view if search.view
    url += '&size=' + search.size.to_s if search.size
    url += '&audiences=' + search.audiences if search.audiences
    search.subjects.each do |s|
      url += '&subjects[]=' +   url_encode(s)
    end if search.subjects
    search.authors.each do |a|
      url += '&authors[]=' +   url_encode(a)
    end if search.authors
    search.series.each do |s|
      url += '&series[]=' +   url_encode(s)
    end if search.series
    search.genres.each do |g|
      url += '&genres[]=' +   url_encode(g)
    end if search.genres
    if type == 'base' || type == ''
      return url
    elsif type == 'add_facet'
      url +=  '&'+ facet[0] + '[]=' +  url_encode(facet[1])
      return url
    elsif type == 'remove_facet'
      remove_from_url = '&'+ facet[0] + '[]=' +   url_encode(facet[1])
      return url.gsub(remove_from_url,'')
    elsif  type == 'change_display'
      remove_from_url = '&view=' + search.view
      return url.gsub(remove_from_url,'')
    elsif type == 'next_page'
      next_page = search.page.to_i + 1
      url += '&page=' + next_page.to_s
      url += '&format=js'
      return url 
    end
  end

  def active_facet_tester(search = '', facet = '')
    if search.subjects && facet[0] == 'subjects'
      return search.subjects.include? facet[1]
    elsif search.genres && facet[0] == 'genres'
      return search.genres.include? facet[1]
    elsif search.authors && facet[0] == 'authors'
      return search.authors.include? facet[1]
    elsif search.series && facet[0] == 'series'
      return search.series.include? facet[1]
    else
      return false
    end
  end

  def if_true_checked(value)
    if value == 'true' || value == true
      return 'checked'
    end
  end

  def format_icon_array
    icon_array = [['a','book','text'], 
                        ['c','music','notated music'], 
                        ['d','music','notated music'], 
                        ['e','globe-americas','cartographic'], 
                        ['f','globe-americas','cartographic'], 
                        ['g','film','moving image'], 
                        ['i','compact-disc','sound recording-nonmusical'], 
                        ['j','compact-disc','sound recording-musical'], 
                        ['k','image','still image'], 
                        ['m','save','software, multimedia'], 
                        ['o','briefcase','kit'], 
                        ['p','briefcase','mixed-material'], 
                        ['r','cube','three dimensional object'],
                        ['t','book','text']
                  ]
    return icon_array
  end

# return correct format icon for items (may require different approach for checkouts, etc.
  def item_format_icon(type_of_resource)
    icon_array = format_icon_array
    icon_array.each do |i|
      if i[2] == type_of_resource
        return i[1]
      end
    end
  end

  def check_cover(id)
    # this needs a ttl
    Rails.cache.fetch("cover" + id.to_s, expires_in: 1.day) do
      url = Settings.cover_url_prefix_lg + id.to_s
      image = MiniMagick::Image.open(url) rescue nil
      if image != nil && image.width > 2
        @result = true
      else
        @result = false
      end
      @result
    end
  end

  def format_due_date(due_date)
    date_array = due_date.split('-')
    formated_date = date_array[1] + '/' + date_array[2] + '/' + date_array[0]
    return formated_date
  end

end

