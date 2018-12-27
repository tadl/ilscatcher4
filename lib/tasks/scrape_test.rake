desc "testing scraping in app vs reaching out to ILSCatcher3 api"
task :scrape_test => :environment do
  require 'io/console'

  puts "This is a test that compares speed of running a few user methods in parallel vs one at a time"
  STDOUT.puts "Please enter your username"
  username = STDIN.gets.chomp
  
  STDOUT.puts "Please enter your password"
  password = STDIN.noecho(&:gets).chomp
  
  puts "Thanks! Getting Started"

  user = User.new
  user.login({:password => password, :username => username})

  if !user.error.blank?
    puts "invalid username or password"
  else
    puts "valid username and password. Testing scrape vs ILSCatcher3 API calls for checkouts"

    i = 0
    api_request_times = []
    while i < 10
      i += 1
      api_start_time = Time.now
      scraper = Scraper.new
      scraper.user_get_preferences(user.token)
      api_end_time = Time.now
      api_request_duration = api_end_time - api_start_time
      puts 'api request number ' + i.to_s + ' took ' + api_request_duration.to_s
      api_request_times.push(api_request_duration)
    end
    api_request_duration_average = api_request_times.inject{ |sum, el| sum + el }.to_f / api_request_times.size
    puts 'average api request time took ' + api_request_duration_average.to_s

    i = 0
    scrape_request_times = []
    while i < 10
      i += 1
      scrape_start_time = Time.now
      scraper = Scraper.new
      scraper.user_get_preferences_2(user.token)
      scrape_end_time = Time.now
      scrape_request_duration = scrape_end_time - scrape_start_time
      puts 'scrape request number ' + i.to_s + ' took ' + scrape_request_duration.to_s
      scrape_request_times.push(scrape_request_duration)
    end
    scrape_request_duration_average = scrape_request_times.inject{ |sum, el| sum + el }.to_f / scrape_request_times.size
    puts 'average scrape request time took ' + scrape_request_duration_average.to_s
    puts 'average api request time took ' + api_request_duration_average.to_s
  end
end