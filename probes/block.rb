#!/usr/bin/env ruby
#coding: utf-8
system 'clear'

class Epub
	# [:title, :author].each do |name|
	# 	define_method(name) do
	# 		instance_variable_get(name)
	# 	end
	# end

	attr_accessor :title, :author

	def initialize
		@title = 'заголовок'
		@author = 'автор'

		puts "#{self.class}.#{__method__}()"
		#puts title
		
		yield
	end
end

epub = Epub.new do |b|
	puts b.title
end
