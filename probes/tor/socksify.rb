#coding: utf-8
system 'clear'

if ARGV.count != 1 then
	puts "Usage: #{__FILE__} <uri>"
	exit 1
end

require 'socksify/http'

uri = URI.parse(ARGV.first)
uri.path = '/' if uri.path.empty?

http = Net::HTTP.SOCKSProxy('127.0.0.1', 9050).start(uri.host, uri.port)
#Net::HTTP.SOCKSProxy('127.0.0.1', 9050).start(uri.host, uri.port) do |http|
  data = http.get(uri.path)
  	puts "#{data.class}"
	puts "#{data.body.size}"
	data.to_hash.each { |k,v| puts "#{k} => #{v}" }

	File.write("#{uri.host}.html",data.body)
#end
http.finish

