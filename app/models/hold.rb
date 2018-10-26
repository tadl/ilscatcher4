class Hold < Item
  include ActiveModel::Model
  attr_accessor :hold_id, :hold_status, :queue_status, :queue_state, :pickup_location

end