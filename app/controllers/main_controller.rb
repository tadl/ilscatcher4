class MainController < ApplicationController
  def index
    @slidedata = {}
    Settings.lists.each do |listgroup|
      @slidedata[listgroup['group']] = {}
    end
    Settings.lists.each do |list|
      @slidedata[list['group']][list['name']] = {}
      @slidedata[list['group']][list['name']]['items'] = Rails.cache.read(list['name'])
      @slidedata[list['group']][list['name']]['prettyname'] = list['prettyname']
    end

  end
end
