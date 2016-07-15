#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'


class A
	def blacklist
		puts "метод A.#{__method__}"
	end
end

class B < A
	def blacklist
		super
		puts "метод B.#{__method__}"
	end
end

b = B.new
b.blacklist
