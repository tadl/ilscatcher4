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

end