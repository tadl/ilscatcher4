class List
  include ActiveModel::Model
  attr_accessor :title, :list_id, :description, :default, :shared, :offset

end