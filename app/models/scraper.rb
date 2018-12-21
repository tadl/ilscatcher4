class Scraper 
  require 'net/http'
  require 'cgi'
  include ActiveModel::Model

  BASE_URL = 'https://catalog.tadl.org/'

  def user_basic_info(token)
    url = Settings.machine_readable + 'eg/opac/myopac/prefs_notify'
    page = scrape_request(url, token)[0]
    if test_for_logged_in(page) == false
      return 'error'
    else
      basic_info = Hash.new
      page.parser.css('body').each do |p|
        basic_info['full_name'] = p.css('span#dash_user').try(:text).strip rescue nil
        basic_info['checkouts'] =  p.css('#dash_checked').try(:text).strip rescue nil
        basic_info['holds'] =  p.css('span#dash_holds').try(:text).strip rescue nil
        basic_info['holds_ready'] = p.css('span#dash_pickup').try(:text).strip rescue nil
        basic_info['fine'] = p.css('span#dash_fines').try(:text).strip.gsub(/\$/, '') rescue nil
        basic_info['card'] = p.at('td:contains("Active Barcode")').try(:next_element).try(:text) rescue nil
        basic_info['default_search'] = p.css('select[@name="opac.default_search_location"] option[@selected="selected"]').attr('value').text rescue nil
        basic_info['pickup_library'] = p.css('select[@name="opac.default_pickup_location"] option[@selected="selected"]').attr('value').text rescue nil
        basic_info['username'] = p.at('td:contains("Username")').next.next.text rescue nil
        basic_info['overdue'] = p.at('#dash_overdue').try(:text).strip rescue nil
        basic_info["email"] = p.at('td:contains("Email Address")').next.next.text rescue nil
        basic_info ["melcat_id"] = p.at('td:contains("MeLCat ID")').next.next.text rescue nil
        basic_info['cards'] = Array.new
        p.css('#card_list').css('.card').each do |c|
          basic_info['cards'].push(c.try(:text).strip)
        end
      end
      return basic_info
    end
  end

  def user_get_checkouts(token)
    url = Settings.machine_readable + 'eg/opac/myopac/circs'
    page = scrape_request(url, token)[0]
    if test_for_logged_in(page) == false
      return {error: 'not logged in'}
    else
      return scrape_checkout_page(page)
    end 
  end
  
  def user_renew_checkouts(token, checkout_ids)
    url = Settings.machine_readable + 'eg/opac/myopac/circs?action=renew'
    checkout_ids = checkout_ids.split(',')
    checkout_ids.each do |c|
      url += '&circ=' + c
    end 
    page = scrape_request(url, token)[0]
    if test_for_logged_in(page) == false
      return {error: 'not logged in'}
    else
      message = page.parser.at_css('div.renew-summary').try(:text).try(:strip)
      errors = page.parser.css('table#acct_checked_main_header').css('tr').drop(1).reject{|r| r.search('span[@class="failure-text"]').present? == false}.map do |c| 
        {
          :message => c.css('span.failure-text').text.strip.try(:gsub, /^Copy /, ''),
          :checkout_id => c.previous.previous.search('input[@name="circ"]').try(:attr, "value").to_s,
          :title => circ_to_title(page, c.previous.previous.search('input[@name="circ"]').try(:attr, "value").to_s).try(:gsub, /:.*/, '').try(:strip),
        }
      end
      checkouts = scrape_checkout_page(page)
      return message, errors, checkouts
    end 
  end


  def user_checkout_history(token, page)
    params = '?token=' + token + '&page=' + page.to_s
    checkout_hash = json_request('checkout_history', params)
    if !checkout_hash['user']['error']
      checkout_hash['checkouts'] = scraped_historical_checkouts_to_full_checkouts(checkout_hash['checkouts']) 
      return checkout_hash
    else
      return 'error'
    end
  end

  def user_get_holds(token)
    url = Settings.machine_readable + 'eg/opac/myopac/holds?limit=41'
    page = scrape_request(url, token)[0]
    if test_for_logged_in(page) == false
      return {error: 'not logged in'}
    else
      return scrape_holds_page(page)
    end 
  end

  def user_manage_holds(token, hold_id, task)
    url = Settings.machine_readable + 'eg/opac/myopac/holds?limit=91'
    params = []
    holds = hold_id.split(',')
    holds.each do |h|
      params.push(['hold_id', h])
    end
    params.push(['action', task])
    page = scrape_request(url, token, params)[0]
    if test_for_logged_in(page) == false
      return 'error'
    else
      return scrape_holds_page(page)
    end
  end

  def user_change_hold_pickup(token, hold_id, hold_status, pickup_location)
    url = Settings.machine_readable + 'eg/opac/myopac/holds/edit?id=' + hold_id
    if hold_status == "Active"
      hold_status = 't'
    else
      hold_status = 'f'
    end
    params = []
    params.push(["hold_id", hold_id])
    params.push(["action", "edit"])
    params.push(["pickup_lib", pickup_location])
    params.push(["expire_time", ""])
    params.push(["frozen", hold_status])
    params.push(["thaw_date", ""])
    page = scrape_request(url, token, params)[0]
    if test_for_logged_in(page) == false
      return 'error'
    else
      holds = scrape_holds_page(page)
      target_hold = ''
      holds.each do |h|
        if h.hold_id == hold_id
          target_hold = h
        end
      end
      return target_hold
    end
  end

  def user_get_preferences(token)
    params = '?token=' + token
    preferences_hash = json_request('preferences', params)
    if !preferences_hash['user']['error']
      return preferences_hash['preferences']
    else
      return 'error'
    end
  end

  def user_change_username(params)
    if params[:current_password].blank?
      return {type: 'username', error: "Current password is required to make this change"}
    end 
    url = Settings.machine_readable + 'eg/opac/myopac/update_username'
    request_params = [["current_pw",   CGI.unescape(params[:current_password])], ["username",  CGI.unescape(params[:username])]]
    page = scrape_request(url, params[:token], request_params)[0]
    if test_for_logged_in(page) == false
      return {type: 'username', error: "Invalid password"}
    end
    test_for_in_use = page.at_css('div:contains("Please try a different username")').text rescue nil
    if test_for_in_use
      return {type: 'username', error: "Username is in use by another patron"}
    else
      return {type: 'username', success: "Username was sucessfully changed"}
    end
  end

  def user_change_password(params)
    if params[:current_password].blank?
      return {type: 'password', error: "Current password is required to make this change"}
    end 
    url = Settings.machine_readable + 'eg/opac/myopac/update_password'
    request_params = [["current_pw",  CGI.unescape(params[:current_password])], ["new_pw",  CGI.unescape(params[:new_password])], ["new_pw2",  CGI.unescape(params[:new_password])]]
    page = scrape_request(url, params[:token], request_params)[0]
    if test_for_logged_in(page) == false
      return {type: 'password', error: "Invalid current password"}
    end
    test_for_invalid_new_password = page.at_css('div:contains("New password is invalid")').text rescue nil
    test_for_bad_old_password = page.at_css('div:contains("Your current password was not correct.")').text rescue nil
    if test_for_bad_old_password
      return {type: 'password', error: "Invalid current password"}
    elsif test_for_invalid_new_password
      return {type: 'password', error: "Password does not meet complexity requirements"}
    else
      return {type: 'password', success: "Password was sucessfully changed"}
    end
  end

  def user_change_email(params)
    if params[:current_password].blank?
      return {type: 'email', error: "Current password is required to make this change"}
    end 
    url = Settings.machine_readable + 'eg/opac/myopac/update_email'
    request_params = [["current_pw",  CGI.unescape(params[:current_password])], ["email",  CGI.unescape(params[:email])]]
    page = scrape_request(url, params[:token], request_params)[0]
    if test_for_logged_in(page) == false
      return {type: 'email', error: "Invalid password"}
    end
    test_for_bad_email = page.at_css('div:contains("Please try a different email address")').text rescue nil
    if test_for_bad_email
      return {type: 'email', error: "Invalid email"}
    else
      return {type: 'email', success: "Email was sucessfully changed"}
    end
  end

  def user_change_alias(params)
    if params[:current_password].blank?
      return {type: 'alias', error: "Current password is required to make this change"}
    end 
    url = Settings.machine_readable + 'eg/opac/myopac/update_alias'
    request_params = [["current_pw",  CGI.unescape(params[:current_password])], ["alias",  CGI.unescape(params[:hold_shelf_alias])]]
    page = scrape_request(url, params[:token], request_params)[0]
    if test_for_logged_in(page) == false
      return {type: 'alias', error: "Invalid password"}
    end
    test_for_in_use = page.at_css('div:contains("Please try a different hold shelf alias")').text rescue nil
    if test_for_in_use
      return {type: 'alias', error: "Hold shelf alias is in use by another patron"}
    else
      return {type: 'alias', success: "Hold shelf alias was sucessfully changed"}
    end
  end

  def user_change_circ_preferences(params)
    params = true_false_to_on_off(params)
    url = Settings.machine_readable + 'eg/opac/myopac/prefs_settings'
    request_params = []
    request_params.push(["opac.default_search_location", params['default_search']])
    request_params.push(["opac.default_pickup_location", params['pickup_library']])
    request_params.push(["history.circ.retention_start", params['keep_circ_history']])
    request_params.push(["history.hold.retention_start", params['keep_hold_history']])
    request_params.push(["history_delete_confirmed", 1])
    request_params.push(["opac.hits_per_page", '10'])
    page = scrape_request(url, params['token'], request_params)[0]
    if test_for_logged_in(page) == false
      return {type: 'circ_prefs', error: "Invalid password"}
    else
      return {type: 'circ_prefs', success: "Circulation preferences were sucessfully changed"}
    end
  end

  def user_change_notify_preferences(params)
    params = true_false_to_on_off(params)
    url = Settings.machine_readable + 'eg/opac/myopac/prefs_notify'
    request_params = []
    request_params.push(["opac.hold_notify.email", params['email_notify']])
    request_params.push(["opac.hold_notify.phone", params['phone_notify']])
    request_params.push(["opac.hold_notify.sms", params['text_notify']])
    request_params.push(["opac.default_phone", params['phone_notify_number']])
    request_params.push(["opac.default_sms_notify", params['text_notify_number']])
    page = scrape_request(url, params['token'], request_params)[0]
    if test_for_logged_in(page) == false
      return {type: 'notify_prefs', error: "Invalid password"}
    else
      return {type: 'notify_prefs', success: "Notification preferences were sucessfully changed"}
    end
  end
  
  def user_get_fines(token)
    params = '?token=' + token
    fines_hash = json_request('fines', params)
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
    payments_hash = json_request('payments', params)
    if !payments_hash['user']['error']
      return payments_hash['payments']
    else
      return 'error'
    end
  end

  def user_get_lists(token)
    params = '?token=' + token
    list_hash = json_request('lists', params)
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

  def user_view_list(token, list_id, page)
    params = '?list_id=' + list_id
    params += '&page=' + page.to_s
    if token
      params += '&token=' + token
    end
    list_hash = json_request('view_list', params)
    if list_hash['list']['no_items'] == '' && list_hash['list']['name'] != ''
      list_hash['items'] = list_items_to_full_items(list_hash['list']['items'])
      list_hash['list'] = list_hash_to_list(list_hash['list'])
      return list_hash
    elsif list_hash['list']['no_items'] != '' && list_hash['list']['name'] == ''
      list_hash['list']['name'] = list_hash['list']['no_items']
      list_hash['list'] = list_hash_to_list(list_hash['list'])
      list_hash['list'].no_items = true
      return list_hash
    elsif list_hash['list']['no_items'] == '' && list_hash['list']['name'] == ''
      list_hash['list'] = list_hash_to_list(list_hash['list'])
      list_hash['list'].no_items = true
      list_hash['list'].error = 'List does not exist or is not public'
      return list_hash
    else
      return 'error'
    end
  end

  def user_password_reset(user)
    params = '?username=' + user
    reset_hash = json_request('reset_password_request', params)
    if reset_hash['message'] == 'complete'
      return reset_hash['message']
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
    hold_confirmation = json_request('place_hold', params)
    hold = Hold.new
    hold.id = id
    if hold_confirmation['hold_confirmation'][0]['error'] == true
      hold.error = hold_confirmation['hold_confirmation'][0]['message'].split('placed')[1]
    elsif hold_confirmation == 'error'
      hold.error = 'Server Error. Please try again later'
    else
      hold.confirmation = hold_confirmation['hold_confirmation'][0]['message']
    end
    return hold
  end

  def item_place_hold_2(token, force, id)
    params = id.split(',').reject(&:empty?).map(&:strip).map {|k| "&hold_target=#{k}" }.join
    url = Settings.machine_readable + 'eg/opac/place_hold?hold_type=T' + params
    intial_request = scrape_request(url, token)
    agent = intial_request[1]
    page = intial_request[0]
    if test_for_logged_in(page) == false
      return 'error'
    else
      hold_form = agent.page.forms[1]
      agent.submit(hold_form)
      page = agent.page
      hold = Hold.new
      page.parser.css('//table#hold-items-list//tr').each do |h|
        hold.id = h.at_css("td[1]//input").try(:attr, "value")
        hold.confirmation = h.at_css("td[2]").try(:text).try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip)
      end
      if !(hold.confirmation =~ /Hold was successfully placed/)
        if hold.confirmation =~ /User already has an open hold on the selected item/
          hold.error = 'You already have this item on hold'
        elsif hold.confirmation =~ /The patron has reached the maximum number of holds/
          hold.error = 'You have reached the maximum number of allowable holds'
        end
        if hold.confirmation == "Placing this hold could result in longer wait times." || hold.confirmation =~ /checked out to the requestor/
          hold.need_to_force = true
        end
      else
        hold.confirmation = "Hold was successfully placed"
      end
      return hold
    end
  end

  def item_marc_format(id)
    url = Settings.machine_readable + 'eg/opac/record/' + id + '?expand=marchtml#marchtml'
    page = scrape_request(url)
    marc = page[0].parser.at_css('.marc_table').to_s.gsub(/\n/,'').gsub(/\t/,'') rescue 'error'
    return marc
  end

  def list_create(token, values)
    params = '?token=' + token
    params += '&name=' + values[:name]
    params += '&description=' + values[:description]
    params += '&shared=' + values[:shared]
    list_confirmation = json_request('create_list', params)
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
    edit_confirmation = json_request('edit_list', params)
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
    share_confirmation = json_request('share_list', params)
    if share_confirmation['message'] && share_confirmation['message'] == 'success'
      return share_confirmation['message']
    else
      return 'error'
    end
  end

  def list_make_default(token, list_id)
    params = '?token=' + token
    params += '&list_id=' + list_id
    make_default_confirmation = json_request('make_default_list', params)
    if make_default_confirmation['message'] && make_default_confirmation['message'] == 'success'
      return make_default_confirmation['message']
    else
      return 'error'
    end
  end

  def list_destroy(token, list_id)
    params = '?token=' + token
    params += '&list_id=' + list_id
    destroy_confirmation = json_request('destroy_list', params)
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
    add_note_confirmation = json_request('add_note_to_list', params)
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
    edit_note_confirmation = json_request('edit_note', params)
    if edit_note_confirmation['message'] && edit_note_confirmation['message'] == 'success'
      return edit_note_confirmation['message']
    else
      return 'error'
    end
  end

  def list_add_item(token,values)
    params = '?token=' + token
    params += '&record_id=' + values[:record_id]
    params += '&list_id=' + values[:list_id]
    add_confirmation = json_request('add_item_to_list', params)
    if add_confirmation['message'] && add_confirmation['message'] == 'success'
      return add_confirmation['message']
    else
      return 'error'
    end
  end

  def list_remove_item(token, values)
    params = '?token=' + token
    params += '&list_item_id=' + values[:list_item_id]
    params += '&list_id=' + values[:list_id]
    remove_confirmation = json_request('remove_item_from_list', params)
    if remove_confirmation['message'] && remove_confirmation['message'] == 'success'
      return remove_confirmation['message']
    else
      return 'error'
    end
  end

  
  private

  def json_request(path = '', params = '')
    uri = URI.parse(BASE_URL + path + '.json' + params)
    response = Net::HTTP.get_response(uri)
    if response.code == '200'
      return JSON.parse(response.body)
    else
      return 'error'
    end
  end

  def scrape_request(url = '', token = '', params = '')
    agent = Mechanize.new
    if !token.blank?
      cookie = Mechanize::Cookie.new('ses', token)
      cookie.domain = '.tadl.org'
      cookie.path = '/'
      agent.cookie_jar.add!(cookie)
    end
    if !params.blank?
      page = agent.post(url, params)
    else
      page = agent.get(url)
    end
    return page, agent
  end

  def test_for_logged_in(page)
    if page.at_css('.login-help-box')
      return false
    else
      return true
    end
  end

  def scraped_checkouts_to_full_checkouts(checkouts_hash)
    query = ''
    checkouts_hash.each do |c|
      query += c[:record_id] + ','
    end
    search = Search.new({:query => query, :type => 'record_id', :size => 82})
    search.get_results
    items = search.results
    checkouts = []
    items.each do |i|
      matching_checkout = checkouts_hash.select {|k| k[:record_id] == i.id.to_s}
      checkout = Checkout.new
      copy_instance_variables(i, checkout)
      checkout.due_date = matching_checkout[0][:due_date]
      checkout.renew_attempts = matching_checkout[0][:renew_attempts]
      checkout.checkout_id = matching_checkout[0][:checkout_id]
      checkout.barcode = matching_checkout[0][:barcode]
      checkouts.push(checkout)
    end
    return checkouts
  end

  def scraped_historical_checkouts_to_full_checkouts(checkouts_hash)
    query = ''
    checkouts_hash.each do |c|
      query += c['record_id'] + ','
    end
    search = Search.new({:query => query, :type => 'record_id', :size => 500})
    search.get_results
    items = search.results
    checkouts = []
    checkouts_hash.each do |c|
      matching_item = items.select{|i| i.id.to_s == c['record_id']}
      checkout = Checkout.new
      copy_instance_variables(matching_item[0], checkout)
      checkout.checkout_date = c['checkout_date']
      checkout.due_date = c['due_date']
      checkout.return_date = c['return_date']
      checkout.barcode = c['barcode']
      if !checkout.id.nil?
        checkouts.push(checkout)
      end
    end
    return checkouts
  end

  def scraped_holds_to_full_holds(holds_hash)
    query = ''
    holds_hash.each do |h|
      query += h[:record_id] + ','
    end
    search = Search.new({:query => query, :type => 'record_id', :size => 100})
    search.get_results
    items = search.results
    holds = []
    items.each do |i|
      matching_hold = holds_hash.select {|k| k[:record_id] == i.id.to_s}
      hold = Hold.new
      copy_instance_variables(i, hold)
      hold.hold_id = matching_hold[0][:hold_id]
      hold.hold_status = matching_hold[0][:hold_status]
      hold.queue_status = matching_hold[0][:queue_status]
      hold.queue_state  = matching_hold[0][:queue_state]
      hold.pickup_location = matching_hold[0][:pickup_location]
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

  def scrape_checkout_page(page)
    checkouts_div = page.parser.css('table#acct_checked_main_header').css('tr').drop(1).reject{|r| r.search('span[@class="failure-text"]').present?}
    raw_checkouts = checkouts_div.map do |c|
      {
        :record_id => clean_record_id(c.search('td[@name="author"]').css('a')[0].try(:attr, "href")),
        :checkout_id => c.search('input[@name="circ"]').try(:attr, "value").to_s,
        :renew_attempts => c.search('td[@name="renewals"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),
        :due_date => c.search('td[@name="due_date"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),
        :iso_due_date => Date.strptime(c.search('td[@name="due_date"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),'%m/%d/%Y').to_s,
        :barcode => c.search('td[@name="barcode"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),
      }
    end
    return scraped_checkouts_to_full_checkouts(raw_checkouts)
  end

  def scrape_holds_page(page)
    holds_div = page.parser.css('tr.acct_holds_temp')
    raw_holds = holds_div.map do |h|
      {
        :record_id => clean_record_id(h.css('td[2]').css('a').try(:attr, 'href').to_s),
        :hold_id => h.search('input[@name="hold_id"]').try(:attr, "value").to_s,
        :hold_status => h.css('td[8]').text.strip,
        :queue_status => h.css('/td[9]/div/div[1]').text.strip.gsub(/AvailableExpires/, 'Ready for Pickup, Expires'),
        :queue_state => h.css('/td[9]/div/div[2]').text.scan(/\d+/).map { |n| n.to_i },
        :pickup_location => h.css('td[5]').text.strip,
      }
    end
    if raw_holds.size != 0
      return scraped_holds_to_full_holds(raw_holds)
    else
      return []
    end
  end 

  def true_false_to_on_off(params)
    processed_params = {}
    params.each do |k,v|
      if v == 'true'
        v = 'on'
      elsif v == 'false'
        v = 'off'
      end
      processed_params[k] = v
    end
    return processed_params
  end

  def clean_record_id(string)
    record_id = string.split('?') rescue '-1'
    if record_id != '-1'
     record_id = record_id[0].gsub('/eg/opac/record/','') 
    end
    return record_id
  end

  def circ_to_title(page, checkout_id)
    target_input = 'input[@value="'+ checkout_id +'"]'
    title = page.at(target_input).try(:parent).try(:next).try(:next).try(:css, 'a')[0].try(:text)
    return title  
  end


end
