class Hold < Item
  include ActiveModel::Model
  attr_accessor :hold_id, :hold_status, :queue_status, :queue_state, :pickup_location, :confirmation, :error, :need_to_force, :pickup_location_code

end