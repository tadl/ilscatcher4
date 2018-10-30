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
      return scraped_checkouts_to_full_checkouts(checkouts_hash['checkouts'])
    else
      return 'error'
    end
  end

  def user_get_holds(token)
    params = '?token=' + token
    holds_hash =  request('holds', params)
    if !holds_hash['user']['error']
      return scraped_holds_to_full_holds(holds_hash['holds'])
    else
      return 'error'
    end
  end

  def user_get_preferences(token)
    params = '?token=' + token
    preferences_hash = request('preferences', params)
    if !preferences_hash['user']['error']
      return preferences_hash['preferences']
    else
      return 'error'
    end
  end

  # TODO: test if passing force works as expected. need sample record
  def item_place_hold(token, force, id)
    params = '?token=' + token + '&record_id=' + id
    if force == 'true'
      params += '&force=true'
    end
    hold_confirmation = request('place_hold', params)
    hold = Hold.new
    hold.id = hold_confirmation['hold_confirmation'][0]['record_id']
    if hold_confirmation['hold_confirmation'][0]['error'] == true
      hold.hold_message = {:error => hold_confirmation['hold_confirmation'][0]['message'] }
    else
      hold.hold_message = {:confirmation => hold_confirmation['hold_confirmation'][0]['message'] }
    end
    return hold
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

  def scraped_checkouts_to_full_checkouts(checkouts_hash)
    query = ''
    checkouts_hash.each do |c|
      query += c['record_id'] + ','
    end
    search = Search.new({:query => query, :type => 'record_id', :size => 82})
    search.get_results
    items = search.results
    checkouts = []
    items.each do |i|
      matching_checkout = checkouts_hash.select {|k| k['record_id'] == i.id.to_s}
      checkout = Checkout.new
      copy_instance_variables(i, checkout)
      checkout.due_date = matching_checkout[0]['due_date']
      checkout.renew_attempts = matching_checkout[0]['renew_attempts']
      checkout.checkout_id = matching_checkout[0]['checkout_id']
      checkout.barcode = matching_checkout[0]['barcode']
      checkouts.push(checkout)
    end
    return checkouts
  end

  def scraped_holds_to_full_holds(holds_hash)
    query = ''
    holds_hash.each do |h|
      query += h['record_id'] + ','
    end
    search = Search.new({:query => query, :type => 'record_id', :size => 100})
    search.get_results
    items = search.results
    holds = []
    items.each do |i|
      matching_hold = holds_hash.select {|k| k['record_id'] == i.id.to_s}
      hold = Hold.new
      copy_instance_variables(i, hold)
      hold.hold_id = matching_hold[0]['hold_id']
      hold.hold_status = matching_hold[0]['hold_status']
      hold.queue_status = matching_hold[0]['queue_status']
      hold.queue_state  = matching_hold[0]['queue_state']
      hold.pickup_location = matching_hold[0]['pickup_location']
      holds.push(hold)
    end
    return holds
  end

  def copy_instance_variables(parent_class, child_class)
    parent_class.instance_variables.each { |v| 
    child_class.instance_variable_set(v, parent_class.instance_variable_get(v)) }
  end

end