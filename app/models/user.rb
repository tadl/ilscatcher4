class User
  include ActiveModel::Model
  attr_accessor :username, :message

  def login(params = '' )
    self.message = 'logged in'
  end

end