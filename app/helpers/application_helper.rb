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
    if type == 'base' || type == ''
      return url
    elsif type == 'add_facet'
      url += facet[0] + '[]=' + facet[1]
      return url
    end
  end
end
