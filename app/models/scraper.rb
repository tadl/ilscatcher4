class Scraper
  require 'net/http'
  require 'cgi'
  include ActiveModel::Model

  BASE_URL = 'https://catalog.tadl.org/'

  def user_basic_info(token)
    params = '?token=' + token
    user_hash =  request('login', params)
    return user_hash
  end

  def user_get_checkouts(token)
    params = '?token=' + token
    checkouts_hash =  request('checkouts', params)
    if !checkouts_hash['user']['error']
      return scraped_checkouts_to_full_items(checkouts_hash['checkouts'])
    else
      return 'error'
    end
  end

  private

  def request(path = '', params = '')
    uri = URI.parse(BASE_URL + path + '.json' + params)
    response = Net::HTTP.get_response(uri)
    if response.code == '200'
      return JSON.parse(response.body)
    else
      return 'error'
    end
  end

  def scraped_checkouts_to_full_items(checkouts_hash)
    query = ''
    checkouts_hash.each do |c|
      query += c['record_id'] + ','
    end
    search = Search.new({:query => query, :type => 'record_id', :size => 82})
    search.get_results
    items = search.results
    items.each do |i|
      matching_checkout = checkouts_hash.select {|k| k['record_id'] == i.id.to_s}
      i.due_date = matching_checkout[0]['due_date']
      i.renew_attempts = matching_checkout[0]['renew_attempts']
      i.checkout_id = matching_checkout[0]['checkout_id']
      i.barcode = matching_checkout[0]['barcode']
    end
  end

end