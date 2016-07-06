#!/usr/bin/env ruby
#coding: UTF-8

require 'net/http'

def uri2file_path(arg)
	Msg::debug("#{self.class}.#{__method__}(#{arg})")

	mode = arg.keys.first
	uri = arg.values.first
	
	case mode
	when :text
		dir = @text_dir
		ext = 'html'
	when :image
		dir = @image_dir
		ext = uri.match('\.(?<ext>[a-z]+)$')
		if not ext.nil? then
			ext = ext[:ext]
		else
			Msg::warning 'неизвестный тип изображения, запрашиваю HTTP-заголовок'
		end
	else
		raise "неизвестный режим '#{mode}'"
	end
	
	file_path = File.join(dir, Digest::MD5.hexdigest(uri)+'.'+ext)
		Msg::debug " file_path: #{file_path}"
	
	return file_path
end

def get_image(uri)
	res = download_object(uri: uri)
end

def download_object(arg)
	#puts("#{self.class}.#{__method__}(#{uri})")

	#uri = URI.escape(uri) if not uri.urlencoded?
	
	uri = URI(arg[:uri])
	redirects_limit = arg[:redirects_limit] || 10		# опасная логика...
	
	raise ArgumentError, 'слишком много перенаправлений' if redirects_limit == 0

	result = {}

	Net::HTTP.start(uri.host, uri.port, :use_ssl => 'https'==uri.scheme) { |http|

		request = Net::HTTP::Get.new(uri.request_uri)
		request['User-Agent'] = "Mozilla/5.0 (X11; Linux i686; rv:39.0) Gecko/20100101 Firefox/39.0 [TestCrawler (admin@kempc.edu.ru)]"

		response = http.request(request)

		case response
		when Net::HTTPRedirection then
			location = response['location']
			puts "перенаправление на '#{location}'"
			result =  send(
				__method__,
				{ :uri => location, :redirects_limit => (redirects_limit-1) }
			)
		when Net::HTTPSuccess then
			result = {
				:data => response.body,
				:headers => response.to_hash,
			}
		else
			response.value
		end
	}
  
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


case ARGV.count
when 1
	uri = ARGV[0]
else
	STDERR.puts "Использование: #{__FILE__} <ссылка>"
	exit 1
end


puts "uri: #{uri}"

res = get_image(uri)

puts "-------------- data ---------------"
puts "#{res[:data].class}"

puts "-------------- headers ---------------"
res[:headers].each_pair { |k,v| puts "#{k} => #{v}" }
