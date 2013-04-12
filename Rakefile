require 'rubygems'
require 'cocoapods'
require 'pathname'
require 'json'
require 'erb'
require 'cgi'

task :default => :update

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
  puts "COUNT: #{sets.count}"

  title("Computing addition dates")
  count_by_date = generate_count_by_date(sets)

  title("Generating graph data")
  graph_data = generate_graph_data(count_by_date)
  json = {
    'total_count' => sets.count,
    'count_by_date' => graph_data,
  }
  File.open('graph.json', 'w+') { |f| f.puts(json.to_json) }

  puts "Page updated."
  `open index.html`
end

#-----------------------------------------------------------------------------#

# @return [Hash{Date => Fixnum}] A sorted hash which contains the number of the
#         Pods added by the date.
#
def generate_count_by_date(sets)
  dates_by_pods = Pod::Specification::Set::Statistics.new(Pod::STATISTICS_CACHE_FILE).creation_dates(sets)
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

# @return [Array<Hash{Symbol => Number}>] Hash which contains the value of the x axis
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


# @return [String] The contents of the index.html file.
#
def generate_html(sets, graph_data)
  graph_data_json      = graph_data.to_json
  graph_data_json.tap {}

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

