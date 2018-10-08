class MainController < ApplicationController
  def index
    @slidedata = Rails.cache.read('listdata')
  end
end
