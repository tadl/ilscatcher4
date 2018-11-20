class Scraper 
  require 'net/http'
  require 'cgi'
  include ActiveModel::Model

  BASE_URL = 'https://catalog.tadl.org/'

  def user_basic_info(token)
    params = '?token=' + token
    user_hash =  request('login', params)
    if !user_hash.key?('error')
      return user_hash
    else
      return 'error'
    end
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

  def user_renew_checkouts(token, checkout_ids)
    #need to pass a record_ids param but it can be whatever (weird ILSCatcher3 stuff..)
    params = '?token=' + token + '&checkout_ids=' + checkout_ids + '&record_ids=1'
    renew_response = request('renew_checkouts', params)
    if !renew_response['user']['error']
      renew_response['checkouts'] = scraped_checkouts_to_full_checkouts(renew_response['checkouts'])
      return renew_response
    else
      return 'error'
    end
  end

  def user_checkout_history(token, page)
    params = '?token=' + token + '&page=' + page.to_s
    checkout_hash = request('checkout_history', params)
    if !checkout_hash['user']['error']
      checkout_hash['checkouts'] = scraped_historical_checkouts_to_full_checkouts(checkout_hash['checkouts']) 
      return checkout_hash
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

  def user_manage_hold(token, hold_id, task)
    params = '?token=' + token
    params += '&hold_id=' + hold_id
    params += '&task=' + task
    holds_hash =  request('manage_hold', params)
    if !holds_hash['user']['error']
      return scraped_holds_to_full_holds(holds_hash['holds'])
    else
      return 'error'
    end
  end

  def user_change_hold_pickup(token, hold_id, hold_status, pickup_location)
    params = '?token=' + token
    params += '&hold_id=' + hold_id
    if hold_status == "Active"
      params += '&hold_state=t'
    else
      params += '&hold_state=f'
    end
    params += '&new_pickup=' + pickup_location
    holds_hash =  request('update_hold_pickup', params)
    if !holds_hash['message'] != 'bad login'
      hold_array = []
      hold_array.push(holds_hash['message'])
      return scraped_holds_to_full_holds(hold_array)
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

  def user_get_fines(token)
    params = '?token=' + token
    fines_hash = request('fines', params)
    if !fines_hash['user']['error']
      fines_and_fees = {}
      fines_and_fees['fines'] = fines_hash['fines']
      fines_and_fees['fees'] = fines_hash['fees']
      return fines_and_fees
    else
      return 'error'
    end
  end

  def user_get_payments(token)
    params = '?token=' + token
    payments_hash = request('payments', params)
    if !payments_hash['user']['error']
      return payments_hash['payments']
    else
      return 'error'
    end
  end

  def user_get_lists(token)
    params = '?token=' + token
    list_hash = request('lists', params)
    if !list_hash['user']['error']
      lists = []
      list_hash['lists'].each do |l|
        list = List.new(l)
        lists.push(l)
      end
      return lists
    else
      return 'error'
    end
  end

  def user_view_list(token, list_id)
    params = '?list_id=' + list_id
    if token
      params += '&token=' + token
    end
    list_hash = request('view_list', params)
    if list_hash['list']['no_items'] == '' && list_hash['list']['name'] != ''
      list_hash['items'] = list_items_to_full_items(list_hash['list']['items'])
      list_hash['list'] = list_hash_to_list(list_hash['list'])
      return list_hash
    elsif list_hash['list']['no_items'] != '' && list_hash['list']['name'] != ''
      list_hash['list'] = list_hash_to_list(list_hash['list'])
      list_hash['list'].no_items = true
      return list_hash
    elsif list_hash['list']['no_items'] == '' && list_hash['list']['name'] == ''
      list_hash['list'] = list_hash_to_list(list_hash['list'])
      list_hash['list'].no_items = true
      list_hash['list'].error = 'List does not exisit or is not public'
      return list_hash
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
    # hold = Hold.new
    # hold.id = hold_confirmation['hold_confirmation'][0]['record_id']
    # if hold_confirmation['hold_confirmation'][0]['error'] == true
    #   hold.hold_message = {:error => hold_confirmation['hold_confirmation'][0]['message'] }
    # else
    #   hold.hold_message = {:confirmation => hold_confirmation['hold_confirmation'][0]['message'] }
    # end
    # return hold
  end

  def list_create(token, values)
    params = '?token=' + token
    params += '&name=' + values[:name]
    params += '&description=' + values[:description]
    params += '&shared=' + values[:shared]
    list_confirmation = request('create_list', params)
    if list_confirmation['message'] && list_confirmation['message'] == 'success'
      return list_confirmation['message']
    else
      return 'error'
    end
  end

  def list_edit(token, values)
    params = '?token=' + token
    params += '&list_id=' + values[:list_id]
    params += '&name=' + values[:name]
    params += '&description=' + values[:description]
    params += '&offset=' + values[:offset]
    edit_confirmation = request('edit_list', params)
    if edit_confirmation['message'] && edit_confirmation['message'] == 'success'
      return edit_confirmation['message']
    else
      return 'error'
    end
  end

  def list_share(token, values)
    params = '?token=' + token
    params += '&list_id=' + values[:list_id]
    params += '&share=' + values[:share]
    params += '&offset=' + values[:offset]
    share_confirmation = request('share_list', params)
    if share_confirmation['message'] && share_confirmation['message'] == 'success'
      return share_confirmation['message']
    else
      return 'error'
    end
  end

  def list_make_default(token, list_id)
    params = '?token=' + token
    params += '&list_id=' + list_id
    make_default_confirmation = request('make_default_list', params)
    if make_default_confirmation['message'] && make_default_confirmation['message'] == 'success'
      return make_default_confirmation['message']
    else
      return 'error'
    end
  end

  def list_destroy(token, list_id)
    params = '?token=' + token
    params += '&list_id=' + list_id
    destroy_confirmation = request('destroy_list', params)
    if destroy_confirmation['message'] && destroy_confirmation['message'] == 'success'
      return destroy_confirmation['message']
    else
      return 'error'
    end
  end

  def list_add_note(token, values)
    params = '?token=' + token
    params += '&list_id=' + values[:list_id]
    params += '&list_item_id=' + values[:list_item_id]
    params += '&note=' + values[:note]
    add_note_confirmation = request('add_note_to_list', params)
    if add_note_confirmation['message'] && add_note_confirmation['message'] == 'success'
      return add_note_confirmation['message']
    else
      return 'error'
    end
  end

  def list_edit_note(token, values)
    params = '?token=' + token
    params += '&list_id=' + values[:list_id]
    params += '&note_id=' + values[:note_id]
    if values[:note]
      params += '&note=' + values[:note]
    end
    edit_note_confirmation = request('edit_note', params)
    if edit_note_confirmation['message'] && edit_note_confirmation['message'] == 'success'
      return edit_note_confirmation['message']
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

  def scraped_historical_checkouts_to_full_checkouts(checkouts_hash)
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
      checkout.checkout_date = matching_checkout[0]['checkout_date']
      checkout.due_date = matching_checkout[0]['due_date']
      checkout.return_date = matching_checkout[0]['return_date']
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

  def list_hash_to_list(list_hash)
    list = List.new
    list.title = list_hash['name']
    list.list_id = list_hash['id']
    list.description = list_hash['description']
    list.more_results = list_hash['more_results']
    list.page = list_hash['page']
    list.no_items = false
    return list
  end 

  def list_items_to_full_items(list_item_hash)
    query = ''
    list_item_hash.each do |l|
      query += l['record_id'] + ','
    end
    search = Search.new({:query => query, :type => 'record_id', :size => 9000})
    search.get_results
    list_items = search.results
    items = []
    list_items.each do |i|
      matching_item = list_item_hash.select {|k| k['record_id'] == i.id.to_s}
      list_item = ListItem.new
      copy_instance_variables(i, list_item)
      list_item.notes = matching_item[0]['notes']
      list_item.list_item_id = matching_item[0]['list_item_id']
      items.push(list_item)
    end
    return items
  end

end