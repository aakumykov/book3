#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'

require 'net/http'

#uri = URI(ARGV[0])
uri = URI('http://www.gravatar.com/avatar/3f1d7c78410432ecfed554f14c5c8fc7?size=40&d=http%3A%2F%2Fwww.opennet.ru%2Fp.gif')

Net::HTTP.start(uri.host, uri.port, use_ssl:('https'==uri.scheme)) { |http|
	response = http.head(uri)
	response = response.to_hash
	response.each_pair { |k,v| puts "#{k} => #{v}" }
}
