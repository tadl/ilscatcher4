desc "create item boxes"
task :item_boxes => :environment do

  require "#{Rails.root}/app/helpers/application_helper"
  include ApplicationHelper

  lists = Settings.lists

  lists.each do |g|

    g['searches'].each do |l|
      search = Search.new l['params'].to_h
      results = search.get_results
      results_with_images = Array.new
      puts "Processing " + l['display_name']

      results.each do |r|
        if check_cover(r.id) == true
          results_with_images.push(r)
        end
      end

      images = []

      results_with_images.first(4).each do |i|
        url = Settings.cover_url_prefix_lg + i.id.to_s
        image = MiniMagick::Image.open(url)
        images.push(image)
      end

      MiniMagick::Tool::Montage.new

      directory_name = Rails.root.to_s + '/app/assets/images/boxes/'
      count = 1
      image_files = []

      images.each do |i|
        this_file = directory_name  + (l['name'] + '_' + count.to_s + '.jpg' )
        i.resize('150x163!')  
        i.write(this_file)
        image_files.push(this_file)
        count += 1
      end
      
      MiniMagick::Tool::Montage.new do |image|
        image_files.each {|i| image << i}
        image.geometry '150x163'
        image.tile '2x2'
        image.mode 'Concatenate'
        image << directory_name + (l['name'] + '_' + "box.jpg")
      end

      image_files.each do |i|
        File.delete(i)
      end

    end

  end

end
