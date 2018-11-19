class ListItem < Item
  include ActiveModel::Model
  attr_accessor :notes, :list_item_id

end