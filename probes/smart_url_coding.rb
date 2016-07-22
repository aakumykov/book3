#!/usr/bin/env ruby
#coding: utf-8
#system 'clear'

require 'uri'

class String
	def urlencoded?
		return true if self.match(/(%[0-9ABCDEF]{2})+/i)
		return false
	end
end

module URI
	def self.smart_encode(str)
		str = URI.smart_decode(str)
		
		return str.gsub(/[^-a-z\/:?&_.~#]+/i) { |m|
			URI.encode(m)
		}
	end

	def self.smart_decode(str)
		return str.gsub(/(%[0-9ABCDEF]{2})+/i) { |m|
			URI.decode(m)
		}
	end
end


case ARGV.size
when 1
	s = ARGV[0]
else
	STDERR.puts "Использование: #{__FILE__} '<uri>' (в кавычках)"
	exit 1
end


puts ''
s = URI.smart_encode s
puts "smart_encode: #{s}"

puts ''
s = URI.smart_decode s
puts "smart_decode: #{s}"

