class Checkout < Item
  include ActiveModel::Model
  attr_accessor :checkout_id, :renew_attempts, :due_date, :iso_due_date, :barcode

end