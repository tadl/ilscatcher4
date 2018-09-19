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
    search.subjects.each do |s|
      url += '&subjects[]=' + s
    end if search.subjects
    search.authors.each do |a|
      url += '&authors[]=' + a
    end if search.authors
    search.series.each do |s|
      url += '&series[]=' + s
    end if search.series
    search.genres.each do |g|
      url += '&genres[]=' + g
    end if search.genres
    if type == 'base' || type == ''
      return URI.encode(url)
    elsif type == 'add_facet'
      url +=  '&'+ facet[0] + '[]=' + facet[1]
      return URI.encode(url)
    elsif type == 'remove_facet'
      remove_from_url = '&'+ facet[0] + '[]=' + facet[1]
      return URI.encode(url.gsub(remove_from_url,''))
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
end
