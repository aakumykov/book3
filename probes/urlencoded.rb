#!/usr/bin/env ruby
#coding: utf-8

class String
	def urlencoded?
		return true if self.match(/(%[0-9ABCDEF]{2})+/i)
		return false
	end
end

arg = ARGV[0].to_s

puts "#{arg} is urlencoded: #{arg.urlencoded?}"


