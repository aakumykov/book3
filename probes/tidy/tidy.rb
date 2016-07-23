#!/usr/bin/env ruby
#coding: utf-8
system 'clear'

def tidyPage input_file
	stdin, stdout, stderr = Open3.popen3 "tidy -utf8 -numeric -quiet -asxhtml --drop-proprietary-tags yes --force-output yes --doctype omit #{input_file}"
	output   = stdout.read.strip
	warnings = stderr.read.split("\n").select {|line| line =~ /line \d+ column \d+ - Warning:/ }
	return output
end

def show_usage
	STDERR.puts "Использование: #{__FILE__} <HTML-файл БД>"
	exit 1
end

case ARGV.count
when 1
	input_file = ARGV.first
else
	show_usage
	exit 1
end

name = input_file.gsub(/\.[^.]+$/,'')
puts "name: #{name}"

output_file = "#{name}-clean.html"
puts "output_file: #{output_file}"

