#!/usr/bin/ruby

require 'optparse'
require 'rubygems'
require 'votigoto'
require 'duration'
require 'tempfile'

def make_filename(show_name, extension, options)
    filename = show_name + '.' + extension
    if options[:skip] then
        if File.exists?(filename) && File.size(filename) > 100 then
            puts "skipping #{filename}"
            return nil
        end
    else 
        counter = 0
        while File.exists?(filename) && File.size(filename) > 100 do
            counter += 1
            filename = (show_name + '.' + counter.to_s + '.' + extension)
        end
    end
    puts "fetch #{filename}"
    return filename
end

def fetch(tivo, program_id, options) 
    show = tivo.show(program_id)
    url = show.content_url
    mak = tivo.mak
    filename = make_filename(show.to_s, 'tivo', options)
    cookie_file = Tempfile.new('cookies').path
    return unless filename
    system(%Q{curl --cookie-jar #{cookie_file} --digest --user "tivo:#{mak}" "#{url}" -o "#{filename}"})
end

def fetch_and_decode(tivo, program_id, options) 
    show = tivo.show(program_id)
    url = show.content_url
    mak = tivo.mak
    filename = make_filename(show.to_s, 'mpg', options)
    cookie_file = Tempfile.new('cookies').path
    return unless filename
    system(%Q{curl --cookie-jar #{cookie_file} --digest --user "tivo:#{mak}" "#{url}" | tivodecode --mak #{mak} -o "#{filename}" -})
end

def nice_file_size(size)
    units = %w{B KB MB GB TB} 
    e = (Math.log(size)/Math.log(1024)).floor 
    s = "%.3f" % (size.to_f / 1024.0**e)
    s.sub(/\.?0*$/, " " + units[e])
end

def nice_duration(msec)
    Duration.new(:seconds => (msec / 1000)).strftime("%h:%M:%S")
end

def print_details(show)
    puts "title: #{show.title}"
    puts "episode_title: #{show.episode_title}"
    puts "source_station: #{show.source_station}"
    puts "program_id: #{show.program_id}"
    puts "series_id: #{show.series_id}"
    puts "source_size: #{nice_file_size(show.source_size)})"
    puts "duration: #{nice_duration(show.duration)}"
    puts "source_channel: #{show.source_channel}"
    puts "capture_date: #{show.capture_date.strftime("%Y-%m-%d %H:%M:%S")}"
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
    opts.on("--skip", "Skip existing files") { |bool|
        options[:skip] = bool
    }
end.parse!

tivo = Votigoto::Base.new(host, mak)

if ! ARGV.empty? then
    ARGV.each { |id|
        if options[:detail] then
            print_details(tivo.show(id))
        elsif options[:decode] then
            fetch_and_decode(tivo, id, options)
            sleep(5)
        else
            fetch(tivo, id, options)
            sleep(5)
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

