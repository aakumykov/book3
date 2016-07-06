#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'

require 'net/http'

[ 
	#'http://img5.xuk.ru/images/photos/00/04/27/47/42747/thumb/77a92b43a9db8b95ec8e7458c3af804d.jpg',
	#'http://www.gravatar.com/avatar/3f1d7c78410432ecfed554f14c5c8fc7?size=40&d=http%3A%2F%2Fwww.opennet.ru%2Fp.gif',
	#'http://ru.wikipedia.org',
	'http://top-fwz1.mail.ru/counter2?js=na;id=77689',
].each do |uri|
	puts '-'*50
	puts uri
	puts '-'*50

	uri = URI(uri)
	
		puts "request_uri: #{uri.request_uri}"

	Net::HTTP.start(uri.host, uri.port, use_ssl:('https'==uri.scheme)) { |http|
		#request = Net::HTTP::Get.new(uri)
		request = Net::HTTP::Head.new(uri)

		puts "#{request}"
		puts '-'*50
		
		response = http.request(request)

		puts "#{response}"
		puts '-'*50
		
		response.to_hash.each_pair { |k,v| puts "#{k} => #{v}" }
	}
end
