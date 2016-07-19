#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'

require 'net/http'
require 'colorize'

# arg = {mode_name: uri}
def download(arg)
	
	uri = URI(arg[:uri])
	mode = arg.fetch(:mode,:full).to_s
	redirects_limit = arg[:redirects_limit] || 10	# опасная логика...
	
		Msg::info ''
		Msg::info "uri: #{uri}"
		Msg::info "mode: #{mode}"
		Msg::info "redirects_limit: #{redirects_limit}"
	
	if 0==redirects_limit then
		Msg::warning "слишком много пененаправлений"
		return nil
	end
	
		puts "request_uri: #{uri.request_uri}"

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
	
		Msg::info ''
		Msg::info "код ответа: #{response.code}, #{response.message}"

	case response
	when Net::HTTPRedirection then
		location = response['location']
			Msg::info "перенаправление на '#{location}'"
		
		result =  send(__method__, {
			uri: location, 
			mode: mode,
			redirects_limit: (redirects_limit-1),
		})
	when Net::HTTPSuccess then
		Msg::debug "response headers: #{response.class}"
		Msg::debug "response body: #{response.body.class} (size: #{response.body.size})"
	
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
	
	def self.debug(msg)
		puts msg.to_s if $DEBUG
	end
	
	def self.green(msg)
		puts msg.to_s.green
	end
	
	def self.grey(msg)
		puts msg.to_s.white
	end
	
	def self.cyan(msg)
		puts msg.to_s.cyan
	end
	
	def self.info(msg)
		puts msg.to_s.blue
	end
	
	def self.notice(msg)
		STDERR.puts msg.to_s.yellow
	end
	
	def self.warning(*msg)
		self.prepare_msg(msg).each {|m|
			STDERR.puts m.to_s.red
		}
	end
	
	def self.error(*msg)
		STDERR.puts "ОШИБКА:".light_white.on_red
		self.prepare_msg(msg).each {|m|
			STDERR.puts m.to_s.light_white.on_red
		}
	end
	
	private
	
	def self.prepare_msg(*msg)
		msg = msg.flatten.map {|m|
			if m.kind_of? Exception then
				[m.message, m.backtrace]
			else
				m
			end
		}
		msg.flatten
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
case ARGV.count
when 0
	Msg::info "внутренний источник ссылок"
	list = [ 
		#'http://img5.xuk.ru/images/photos/00/04/27/47/42747/thumb/77a92b43a9db8b95ec8e7458c3af804d.jpg',
		#'http://www.gravatar.com/avatar/3f1d7c78410432ecfed554f14c5c8fc7?size=40&d=http%3A%2F%2Fwww.opennet.ru%2Fp.gif',
		#'https://ru.wikipedia.org',
		#'http://opennet.ru',
		'http://top-fwz1.mail.ru/counter2?js=na;id=77689',
	]
else
	Msg::info "внешний источник ссылок"
	list = ARGV
end

list.each { |uri|
	data = download(uri: uri)
	
	puts ''
	puts "-------------- headers ---------------"
	data[:headers].each_pair { |k,v| puts "#{k} => #{v}" }
	
	puts ''
	puts "-------------- data ---------------"
	puts "байт: #{data[:data].bytes.count}"
	puts "строк: #{data[:data].lines.count}"
}
