#!/usr/bin/env ruby
#coding: utf-8

require 'uri'

class String
	def urlencoded?
		return true if self.match(/(%[0-9ABCDEF]{2})+/i)
		return false
	end
end

def show_usage
	STDERR.puts "Использование: #{__FILE__} [decode|encode|test] <string>"
	exit 1
end


case ARGV.count
when 1
	action = 'test'
	subject = ARGV[0].to_s
when 2
	action = ARGV.first
	subject = ARGV.last
else
	show_usage
end


case action
when 'decode'
	if subject.urlencoded? then
		puts URI.decode(subject)
	else
		puts "Строка и так не закодирована"
	end
when 'encode'
	if subject.urlencoded? then
		puts "Строка уже закодирована"
	else
		puts URI.encode(subject)
	end
when 'test'
	if subject.urlencoded? then
		puts "Строка: '#{subject}'"
		puts "РЕЗУЛЬТАТ: закодирована"
	else
		puts "Строка: '#{subject}'"
		puts "РЕЗУЛЬТАТ: не закодирована"
	end
else
	show_usage
end

