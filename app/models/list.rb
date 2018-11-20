class List
  include ActiveModel::Model
  attr_accessor :title, :list_id, :description, :default, :shared, :offset, :no_items, :empty, 
                :error, :more_results, :page

  def create(token, params)
    scraper = Scraper.new
    new_list_request = scraper.list_create(token, params)
    if new_list_request != 'error'
      return new_list_request
    else
      return {:error => 'unable to create list'}
    end
  end

  def edit(token, params)
    scraper = Scraper.new
    edit_list_request = scraper.list_edit(token, params)
    if edit_list_request != 'error'
      return edit_list_request
    else
      return {:error => 'unable to edit list'}
    end
  end

  def share(token, params)
    scraper = Scraper.new
    share_list_request = scraper.list_share(token, params)
    if share_list_request != 'error'
      return share_list_request
    else
      return {:error => 'unable to change privacy settings of this list'}
    end
  end

  def make_default(token, params)
    scraper = Scraper.new
    make_default_list_request = scraper.list_make_default(token, params)
    if make_default_list_request != 'error'
      return make_default_list_request
    else
      return {:error => 'unable to change privacy settings of this list'}
    end
  end

end