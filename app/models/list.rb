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

  def make_default(token, list_id)
    scraper = Scraper.new
    make_default_list_request = scraper.list_make_default(token, list_id)
    if make_default_list_request != 'error'
      return make_default_list_request
    else
      return {:error => 'unable to make this list the default list'}
    end
  end

  def destroy(token, list_id)
    scraper = Scraper.new
    destroy_list_request = scraper.list_destroy(token, list_id)
    if destroy_list_request != 'error'
      return destroy_list_request
    else
      return {:error => 'unable to delete this list'}
    end
  end

  def add_note(token, params)
    scraper = Scraper.new
    add_note_request = scraper.list_add_note(token, params)
    if add_note_request != 'error'
      return add_note_request
    else
      return {:error => 'unable to add note to this list'}
    end
  end

  def edit_note(token, params)
    scraper = Scraper.new
    edit_note_request = scraper.list_edit_note(token, params)
    if edit_note_request != 'error'
      return edit_note_request
    else
      return {:error => 'unable to edit this note'}
    end
  end

end