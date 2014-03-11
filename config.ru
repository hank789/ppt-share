# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
run MakeSlide::Application

memory_usage = (`ps -o rss= -p #{$$}`.to_i / 1024.00).round(2)
puts "=> Memory usage: #{memory_usage} Mb"