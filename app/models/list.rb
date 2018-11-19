class List
  include ActiveModel::Model
  attr_accessor :title, :list_id, :description, :default, :shared, :offset, :no_items, :empty, 
                :error, :more_results, :page

end