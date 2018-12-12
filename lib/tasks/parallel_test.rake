desc "testing parallel processing"
task :test_parallel => :environment do
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
    puts "valid username and password. fetching holds, checkouts, lists, preferences"
    tasks = [{:action => 'TEMP_get_checkouts'}, {:action => 'TEMP_get_holds', :param => 'false'}, { :action => 'TEMP_get_lists'}, {:action => 'TEMP_get_preferences'}]
    
    puts 'Starting parallel tasks...'
    parallel_start = Time.now
    Parallel.each(tasks, in_threads: 4){|task|
      if !task[:param]
        do_it = user.send(task[:action])
      else
        do_it = user.send(task[:action], task[:param])
      end
    }
    parallel_end = Time.now
    parallel_time = parallel_end - parallel_start
    
    puts 'Starting running tasks one at a time...'
    regular_start = Time.now
    tasks.each do |task|
      if !task[:param]
        do_it = user.send(task[:action])
      else
        do_it = user.send(task[:action], task[:param])
      end
    end
    regular_end = Time.now
    regular_time = regular_end - regular_start

    puts 'It took ' + parallel_time.to_s + ' seconds running in parallel'
    puts 'It took ' + regular_time.to_s + ' seconds running each task one at a time'
  end
end