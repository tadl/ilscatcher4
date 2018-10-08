class MainController < ApplicationController

  def index
    @list_groups = Settings.lists
    @carousel_sections = []
    #@screensaver stuff for opac goes here, we might want to redo this so I'm not duplicating it -- yet.

    @list_groups.each do |lg|
      group = lg["group"]
      lg["searches"].each do |s|
        list = {}
        list[group] = {}
        list[group]["title"] = s["name"]
        list[group]["nice_title"] = s["display_name"]
        list[group]["items"] = Rails.cache.read(s["name"])
        @carousel_sections.push(list[group])
      end

    end

  end

end
