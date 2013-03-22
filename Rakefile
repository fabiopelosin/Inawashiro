require 'rubygems'
require 'cocoapods'
require 'pathname'
require 'json'
require 'erb'
require 'cgi'

task :default => :deploy

#-----------------------------------------------------------------------------#
# These tasks assume to be in sibling directory to the CocoaPods gem
#-----------------------------------------------------------------------------#

desc "Update & Deploy"
task :deploy => :update do
  title("Deploying")
  sh "git add ."
  sh "git commit -m 'update - #{Time.now.to_s}'"
  sh "git push"
  sh "open http://irrationalfab.github.com/Inawashiro/"
end

#-----------------------------------------------------------------------------#

desc "Update the page"
task :update do
  title("Updating master repo")
  sh "pod repo update master"
  sets = Pod::Source.new(Pathname.new(File.expand_path "~/.cocoapods/master")).pod_sets

  title("Computing addition dates")
  count_by_date = generate_count_by_date(sets)

  title("Massaging data")
  graph_data = generate_graph_data(count_by_date)
  releases_data = generate_releases_data
  stats = generate_stats(count_by_date)

  title("Generating HTML")
  html = generate_html(sets, graph_data, releases_data, stats)
  File.open('index.html', 'w+') { |f| f.puts(html) }

  puts "Page updated."
end

#-----------------------------------------------------------------------------#

# @return [Hash{Date => Fixnum}] A sorted hash which contains the number of the
#         Pods added by the date.
#
def generate_count_by_date(sets)
  dates_by_pods = Pod::Specification::Set::Statistics.instance.creation_dates(sets)
  dates = dates_by_pods.values
  min_date = dates.min - (24 * 3600)
  count_by_date = {Time.utc(min_date.year, min_date.month, min_date.day) => 0}
  dates_by_pods.each do |name, date|
    key = Time.utc(date.year, date.month, date.day)
    count_by_date[key] ||= 0
    count_by_date[key] += 1
  end
  count_by_date.sort_by{|date, count| date}
end

# @return [Hash{Symbol => Number}] Hash which contains the value of the x axis
#         (the dates expressed in the UNIX format) and of the y axis (the
#         cumulated number of added Pods on a specific date).
#
def generate_graph_data(count_by_date)
  graph_data = []
  total_count = 0
  count_by_date.each do |date, count|
    total_count += count
    graph_data <<  {:x => date.to_i, :y => total_count}
  end
  graph_data
end

# @return [Array<Fixnum, String>] A tuple where the dates are associated with
# the release tags. Pre-release tags and patch version are ignored.
#
def generate_releases_data
  releases_data = []
  Dir.chdir('../CocoaPods') do
    tags_dates = `git for-each-ref --format="%(taggerdate): %(refname)" --sort=-taggerdate refs/tags`
    tags_dates.split("\n").each do |log|
      match = log.match(/(.*): refs\/tags\/(.*)/)
      next if match[2] =~ /rc/ || match[2] !~ /[0-9]+\.[0-9]+\.0/
      releases_data <<  [Time.parse(match[1]).to_i, match[2]] if match
    end
  end
  releases_data
end

# @return [Hash{Symbol => Fixnum}] Some interesting stuff.
#
def generate_stats(count_by_date)
  stats = {}
  milestones_data = []
  count = 0
  cumulated_count_last_30_days = 0
  last_30_days_time = Time.utc(Time.now.year, Time.now.month, Time.now.day) - (30 * 24 * 3600)
  hundreds_digit = 0
  count_by_date.each do |date, date_count|
    count += date_count
    new_hundreds_digit = (count / 100).to_i
    milestones_data << [date.to_i, "#{new_hundreds_digit}00"] if new_hundreds_digit != hundreds_digit
    hundreds_digit = new_hundreds_digit
    cumulated_count_last_30_days += date_count if(date > last_30_days_time)
  end
  addition_rate = (cumulated_count_last_30_days.to_f/30.0).round(1)
  missing_pods_to_next_milestone = ((count / 100).to_i + 1) * 100 - count
  days_to_milestone = (missing_pods_to_next_milestone.to_f / addition_rate).round(1)

  stats[:count] = count
  stats[:milestones_data] = milestones_data
  stats[:days_to_milestone] = days_to_milestone
  stats[:addition_rate] = addition_rate
  stats
end

# @return [String] The contents of the index.html file.
#
def generate_html(sets, graph_data, releases_data, stats)
  graph_data_json      = graph_data.to_json
  releases_data_json   = releases_data.to_json
  milestones_data_json = stats[:milestones_data].to_json
  # Silence Ruby warnings for unused
  # variables as they binded to the
  # ERB template.
  graph_data_json.tap {}
  milestones_data_json.tap {}
  releases_data_json.tap {}

  pods_columns  = []
  columns_count = 4
  pods_per_column = stats[:count].to_f/columns_count.ceil
  (0..columns_count-1).each do |column|
    from = pods_per_column * column
    from += 1 unless from.zero?
    to = pods_per_column * (column + 1)
    pods_columns << sets[from..to].map(&:specification)
  end

  template = ERB.new(File.open('template.html', 'rb').read)
  template.result(binding)
end

#-----------------------------------------------------------------------------#

# Prints a title like a boss!
#
# @return [void]
#
def title(string)
  puts "\033[0;32m#{string}\e[0m"
end

