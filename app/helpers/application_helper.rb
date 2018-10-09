module ApplicationHelper

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
    puts value.to_s
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
    Rails.cache.fetch("cover" + id.to_s) do
      url = 'https://catalog.tadl.org/opac/extras/ac/jacket/medium/r/' + id.to_s
      image = MiniMagick::Image.open(url) rescue nil
      if image != nil && image.width > 2
        @result = true
      else
        @result = false
      end
      @result
    end
  end

end

