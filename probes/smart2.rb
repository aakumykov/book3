#!/usr/bin/env ruby
#coding: utf-8
system 'clear'

require 'uri'

class String
	def urlencoded?
		return true if self.match(/(%[0-9ABCDEF]{2})+/i)
		return false
	end
end

module URI
	def self.smart_encode(str)
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

puts '-------- encode --------'
es = URI.smart_encode s
es0 = URI.encode(s)
puts "оригинальная: #{s}"
puts "умно закодирована: #{es}"
puts "проверка---------: #{es0}"
puts es==es0

puts '-------- decode --------'
ds = URI.smart_decode s
ds0 = URI.decode(s)
puts "оригинальная: #{s}"
puts "умно раскодирована: #{ds}"
puts "проверка----------: #{ds0}"
puts ds==ds0
