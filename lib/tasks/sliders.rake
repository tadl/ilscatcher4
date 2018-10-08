desc "update and cache data for sliders"
task :sliders => :environment do

  require "#{Rails.root}/app/helpers/application_helper"
  include ApplicationHelper

  lists = Settings.lists

  lists.each do |l|
    search = Search.new l['params'].to_h
    results = search.get_results
    results_with_images = Array.new
    puts "Processing " + l['prettyname']
    results.each do |r|
      if check_cover(r.id) == true
        results_with_images.push(r)
      end
    end
    Rails.cache.write(l['name'], results_with_images)
  end

end

