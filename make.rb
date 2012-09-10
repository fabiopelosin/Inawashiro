#!/usr/bin/env ruby

require 'rubygems'
require 'cocoapods'
require 'googlecharts'
require 'pathname'
require 'json'
require 'erb'
require 'cgi'


`pod repo update master`

sets = Pod::Source.new(Pathname.new(File.expand_path "~/.cocoapods/master")).pod_sets
dates_by_pods = Pod::Specification::Statistics.instance.creation_dates(sets)

dates = dates_by_pods.values

date = dates.min - (24 * 3600)
pods_added_by_date = {Time.utc(date.year, date.month, date.day) => 0}
dates_by_pods.each do |name, date|
  key = Time.utc(date.year, date.month, date.day)
  pods_added_by_date[key] ||= 0
  pods_added_by_date[key] += 1
end

serie_data = []
milestones_data = []
cumulated_count = 0
cumulated_count_last_30_days = 0
last_30_days_time = Time.utc(Time.now.year, Time.now.month, Time.now.day) - (30 * 24 *3600)
hundreds_digit = 0
pods_added_by_date.sort_by{|date, count| date}.each do |date, count|
  cumulated_count += count
  serie_data <<  {:x => date.to_i, :y => cumulated_count}
  new_hundreds_digit = (cumulated_count / 100).to_i
  milestones_data << [date.to_i, "#{new_hundreds_digit}00"] if new_hundreds_digit != hundreds_digit
  hundreds_digit = new_hundreds_digit
  cumulated_count_last_30_days += count if(date > last_30_days_time)
end

tags_data = []
Dir.chdir('/Users/fabio/Documents/GitHub/CP/CocoaPods') do
  tags_dates = `git for-each-ref --format="%(taggerdate): %(refname)" --sort=-taggerdate refs/tags`
  tags_dates.split("\n").each do |log|
    match = log.match(/(.*): refs\/tags\/(.*)/)
    next if match[2] =~ /rc/ || match[2] !~ /[0-9]+\.[0-9]+\.0/
    tags_data <<  [Time.parse(match[1]).to_i, match[2]] if match
  end
end


addition_rate = (cumulated_count_last_30_days.to_f/30.0).round(1)
missing_pods_to_next_milestone = ((cumulated_count / 100).to_i + 1) * 100 - cumulated_count
missing_days_to_milestone = (missing_pods_to_next_milestone.to_f / addition_rate).round(1)

serie_data_json      =  serie_data.to_json
milestones_data_json =  milestones_data.to_json
tags_data_json       =  tags_data.to_json
pods_count           =  cumulated_count
pods_columns         =  []
columns_count        =  4
pods_per_column = pods_count.to_f/columns_count.ceil
(0..columns_count-1).each do |column|
  from = pods_per_column * column
  from += 1 unless from.zero?
  to = pods_per_column * (column + 1)

  pods_columns << sets[from..to].map(&:specification)
end
template = ERB.new(File.open('template.html', 'rb').read)
File.open('index.html', 'w+') { |f| f.puts(template.result(binding)) }

puts "Page updated."
` open index.html`
