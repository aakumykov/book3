#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'

def foo(arg={})
	puts "#{__method__}(#{arg}, size: #{arg.size})"
	arg.each_pair { |k,v| puts "#{k}: #{arg[k]}" }
	puts "arg.first.keys.first: #{arg.first.keys.first}"
	puts "arg.first.values.first: #{arg.first.values.first}"
end

foo(
	a:'AA',
	b:'BB',
)
