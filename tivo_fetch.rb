#!/usr/bin/ruby

require 'optparse'
require 'rubygems'
require 'votigoto'
require 'duration'

def fetch(tivo, program_id) 
    show = tivo.show(program_id)
    url = show.content_url
    mak = tivo.mak
    filename = show.to_s + '.tivo'
    cookie_file = Tempfile.new('cookies').path
    puts filename
    system(%Q{curl --cookie-jar #{cookie_file} --digest --user "tivo:#{mak}" "#{url}" -o "#{filename}"})
end

def fetch_and_decode(tivo, program_id) 
    show = tivo.show(program_id)
    url = show.content_url
    mak = tivo.mak
    filename = show.to_s + '.mpg'
    cookie_file = Tempfile.new('cookies').path
    puts filename
    system(%Q{curl --cookie-jar #{cookie_file} --digest --user "tivo:#{mak}" "#{url}" | tivodecode --mak #{mak} -o "#{filename}" -})
end

def nice_file_size(size)
    units = %w{B KB MB GB TB} 
    e = (Math.log(size)/Math.log(1024)).floor 
    s = "%.3f" % (size.to_f / 1024.0**e)
    s.sub(/\.?0*$/, " " + units[e])
end

def nice_duration(msec)
    Duration.new(:seconds => (msec / 60000.0).round * 60).strftime("%h:%M")
end

def print_details(show)
    puts "title: #{show.title}"
    puts "episode_title: #{show.episode_title}"
    puts "source_station: #{show.source_station}"
    puts "program_id: #{show.program_id}"
    puts "series_id: #{show.series_id}"
    puts "source_size: " + nice_file_size(show.source_size)
    puts "duration: " + nice_duration(show.duration)
    puts "source_channel: #{show.source_channel}"
    puts "capture_date: " + show.capture_date.strftime("%Y-%m-%d %H:%M:%S")
    puts "in_progress: #{show.in_progress}"
    puts
end

host = nil
mak = nil

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: tivo_fetch.rb [options]"
    
    opts.on("--host HOST", "Host") { |val|
        host = val
    }
    opts.on("--mak MAK", "Media Access Key") { |val|
        mak = val
    }
    opts.on("--detail", "Details") { |bool|
        options[:detail] = bool
    }
    opts.on("--decode", "Decode") { |bool|
        options[:decode] = bool
    }
end.parse!

tivo = Votigoto::Base.new(host, mak)

if ! ARGV.empty? then
    ARGV.each { |id|
        if options[:detail] then
            print_details(tivo.show(id))
        elsif options[:decode] then
            fetch_and_decode(tivo, id)
        else
            fetch(tivo, id)
        end
    }
else
    tivo.shows.each { |show|
        if options[:detail] then
            print_details(show)
        else
            puts "[#{show.program_id}] #{show}"
        end
    }
end

