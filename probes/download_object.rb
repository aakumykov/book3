#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'

require 'net/http'

# arg = {mode_name: uri}
def download(arg)
	
	uri = URI(arg[:uri])
	mode = arg[:mode].to_s
	redirects_limit = arg[:redirects_limit] || 10	# опасная логика...
	
	if 0==redirects_limit then
		Msg::warning "слишком много пененаправлений"
		return nil
	end

	begin
		http = Net::HTTP.start(
			uri.host, 
			uri.port, 
			:use_ssl => ('https'==uri.scheme)
		)
	rescue => e
		Msg::warning "#{e.message} (#{uri.to_s})"
		return nil
	end

	case mode
	when 'headers'
		request = Net::HTTP::Head.new(uri.request_uri)
	else
		request = Net::HTTP::Get.new(uri.request_uri)
	end

	#request['User-Agent'] = @book.user_agent
	request['User-Agent'] = "Mozilla/5.0 (X11; Linux i686; rv:39.0) Gecko/20100101 Firefox/39.0 [TestCrawler (admin@kempc.edu.ru)]"


	response = http.request(request)

	case response
	when Net::HTTPRedirection then
		location = response['location']
			Msg::debug "перенаправление на '#{location}'"
		
		result =  send(__method__, {
			uri: location, 
			mode: mode,
			redirects_limit: (redirects_limit-1),
		})
	when Net::HTTPSuccess then
		result = {
			:data => response.body,
			:headers => response.to_hash,
		}
	else
		Msg::warning "неприемлемый ответ сервера: '#{response.value}"
		return nil
	end

	return result
end

class Msg
	#~ def self.debug(msg)
		#~ puts msg
	#~ end
	
	def self.debug(msg, params={})
		params.fetch(:nobr,false) ? print(msg) : puts(msg)
		#puts "#{msg}, nobr: #{params.fetch(:nobr,false)}"
	end
	
	def self.info(msg)
		puts msg
	end
	
	def self.warning(msg)
		STDERR.puts "ВНИМАНИЕ: #{msg}"
	end
	
	def self.error(msg)
		STDERR.puts "ОШИБКА: #{msg}"
	end
end


# case ARGV.count
# when 1
# 	uri = ARGV[0]
# else
# 	STDERR.puts "Использование: #{__FILE__} <ссылка>"
# 	exit 1
# end
#puts "uri: #{uri}"

[ 
	'http://img5.xuk.ru/images/photos/00/04/27/47/42747/thumb/77a92b43a9db8b95ec8e7458c3af804d.jpg',
	'http://www.gravatar.com/avatar/3f1d7c78410432ecfed554f14c5c8fc7?size=40&d=http%3A%2F%2Fwww.opennet.ru%2Fp.gif',
	'http://ru.wikiprgedia.org',
].each do |uri|
	# puts '-'*50; puts uri; puts '-'*50
	data = download(uri: uri)
	
	# puts "-------------- headers ---------------"
	# data[:headers].each_pair { |k,v| puts "#{k} => #{v}" }
	
	# puts "-------------- data ---------------"
	# puts "data[:data].class: #{data[:data].class}"
end