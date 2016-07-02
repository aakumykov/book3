#!/usr/bin/env ruby
#coding: utf-8
system 'clear'

require 'uri'
require 'htmlentities'

he = HTMLEntities.new('html4')

s = he.decode("http://www.opennet.ru/search.shtml?words=&#037;D0&#037;CF&#037;CC&#037;CE&#037;CF&#037;D3&#037;D4&#037;D8&#037;C0")

puts s
puts "#{s}"

puts URI.encode('полностью')

puts URI.decode(s)

