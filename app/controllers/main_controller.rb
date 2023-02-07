class MainController < ApplicationController

  def index
    @list_groups = Settings.lists
    @carousel_sections = {}
    #@screensaver stuff for opac goes here, we might want to redo this so I'm not duplicating it -- yet.

    @list_groups.each do |lg|
      group = lg["group"]
      section_lists = []

      lg["searches"].each do |s|
        list = {}
        list["title"] = s["name"]
        list["nice_title"] = s["display_name"]
        list["search_link"] = '/search?' + s["params"]
        if params[:compact] != 'true' && params[:format] != 'html'
          list["items"] = Rails.cache.read(s["name"])
        end
       section_lists.push(list)
      end

      @carousel_sections.store(group, section_lists)

    end

    respond_to do |format|
      format.html
      format.json {render :json => {:featured_items => @carousel_sections}}
    end

  end

end
