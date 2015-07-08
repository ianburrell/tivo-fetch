#!/usr/bin/ruby

require 'optparse'
require 'rubygems'
require 'votigoto'
require 'duration'
require 'tempfile'

class TivoFetcher

  def initialize(tivo, show, options)
    @mak = tivo.mak
    @show = show
    @options = options
  end

  def make_filename(extension)
    if @options[:show_dir] && (@show.episode_number || @show.episode_title) then
      Dir.mkdir(@show.title) unless Dir.exists?(@show.title)
      base_name = @show.title + '/' + (@show.episode_number ? sprintf("S%04d ", @show.episode_number) : '') + (@show.episode_title ? @show.episode_title : '')
    else
      base_name = @show.to_s
    end
    filename = base_name + '.' + extension
    if @options[:skip] then
      if File.exists?(filename) && File.size(filename) > 100 then
        puts "skipping #{filename}"
        return nil
      end
    else 
      counter = 0
      while File.exists?(filename) && File.size(filename) > 100 do
        counter += 1
        filename = (base_name + '.' + counter.to_s + '.' + extension)
      end
    end
    puts "fetch #{filename}"
    return filename
  end

  def fetch_cmd
    url = @show.content_url
    cookie_file = Tempfile.new('cookies').path
    return %Q{curl --cookie-jar #{cookie_file} --digest --user "tivo:#{@mak}" "#{url}"}
  end

  def smart_fetch
    if @options[:encode] then
      fetch_and_encode
    elsif @options[:decode] then
      fetch_and_decode
    else
      fetch
    end
  end
  
  def fetch 
    filename = make_filename("tivo")
    return unless filename
    cmd = fetch_cmd()
    temp_filename = filename + ".tmp"
    cmd += %Q{ -o "#{temp_filename}"}
    puts(cmd)
    system(cmd) or raise "#{cmd} failed: $?"
    File.rename(temp_filename, filename)
    sleep(2)
  end

  def fetch_and_decode
    filename = make_filename("mpg")
    return unless filename
    cmd = fetch_cmd()
    temp_filename = filename + ".tmp"
    cmd += %Q{ | tivodecode --mak #{@mak} -o "#{temp_filename}" -}
    puts cmd
    system(cmd) or raise "#{cmd} failed: $?"
    File.rename(temp_filename, filename)
    sleep(2)
  end

  def fetch_and_encode
    filename = make_filename("m4v")
    return unless filename
    cmd = fetch_cmd()
    temp_filename = filename + ".tmp"
    cmd += %Q{ | tivodecode --mak #{@mak} -}
    cmd += %Q{ | mencoder -quiet -profile low -o "#{temp_filename}" -}
    puts cmd
    system(cmd) or raise "#{cmd} failed: $?"
    File.rename(temp_filename, filename)
    sleep(2)
  end

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
    puts "source_size: #{nice_file_size(show.source_size)}"
    puts "duration: #{nice_duration(show.duration)}"
    puts "source_channel: #{show.source_channel}"
    puts "capture_date: #{show.capture_date.strftime("%Y-%m-%d %H:%M:%S")}"
    puts "in_progress: #{show.in_progress}"
    puts "episode_number: #{show.episode_number}"
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
  opts.on("--mp4", "Encode MP4") { |bool|
    options[:encode] = bool
  }
  opts.on("--fetch", "Fetch") { |bool|
    options[:fetch] = bool
  }
  opts.on("--skip", "Skip existing files") { |bool|
    options[:skip] = bool
  }
  opts.on("--show", "Show directories") { |bool|
    options[:show_dir] = bool
  }
end.parse!

tivo = Votigoto::Base.new(host, mak)

if ! ARGV.empty? then
  ARGV.each do |id|
    if options[:detail] then
      print_details(tivo.show(id))
    else
      TivoFetcher.new(tivo, tivo.show(id), options).smart_fetch()
    end
  end
else
  tivo.shows.each do |show|
    if options[:detail] then
      print_details(show)
    elsif options[:decode] || options[:fetch] || options[:encode] then
      next if show.in_progress
      TivoFetcher.new(tivo, show, options).smart_fetch()
    else
      puts "[#{show.program_id}] #{show}"
    end
  end
end

