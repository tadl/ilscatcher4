desc "update and cache data for sliders"
task :sliders => :environment do

  require "#{Rails.root}/app/helpers/application_helper"
  include ApplicationHelper

  lists = Settings.lists
  groups = {}

  lists.each do |g|
    groups[g['group']] = {}
    g['searches'].each do |l|
      search = Search.new l['params'].to_h
      results = search.get_results
      results_with_images = Array.new
      puts "Processing " + l['name']
      results.each do |r|
        if check_cover(r.id) == true
          results_with_images.push(r)
        end
      end
      groups[g['group']][l['name']] = {}
      groups[g['group']][l['name']]['name'] = l['name']
      groups[g['group']][l['name']]['items'] = results_with_images
    end
  end
  Rails.cache.write('listdata', groups)

end

