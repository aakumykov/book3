#!/usr/bin/env ruby
# coding: utf-8

require 'uri'
require 'net/http'

# 
def load_page(arg)
	puts "#{__method__}()"

	#uri = URI.escape(uri) if not uri.urlencoded?
	
	uri = URI(arg[:uri])
    redirects_limit = arg[:redirects_limit] || 10		# опасная логика...
    
	raise ArgumentError, 'слишком много перенаправлений' if redirects_limit == 0

	data = {}

	Net::HTTP.start(uri.host, uri.port, :use_ssl => 'https'==uri.scheme) { |http|

		request = Net::HTTP::Get.new(uri.request_uri)
		request['User-Agent'] = 'Mozilla/5.0 (X11; Linux i686; rv:39.0) Gecko/20100101 Firefox/39.0'

		response = http.request request

		case response
		when Net::HTTPRedirection then
			location = response['location']
			puts "перенаправление на '#{location}'"
			data =  send(
				__method__,
				{ :uri => location, :redirects_limit => (redirects_limit-1) }
			)
		when Net::HTTPSuccess then
			data = {
				:headers => response.to_hash,
				:data => response.body,
			}
		else
			response.value
		end
	}
	
	#puts "========== Headers: =========="
	#data[:headers].each_pair { |k,v| puts "#{k}: #{v}" }
	#puts "=========================="
  
	return data
end

def recode_page(page, headers, target_charset='UTF-8')
	puts "#{__method__}()"

	page_charset = nil
	headers_charset = nil
	
	pattern = Regexp.new(/charset\s*=\s*['"]?(?<charset>[^'"]+)['"]?/i)

	page_charset = page.match(pattern)
	page_charset = page_charset[:charset] if not page_charset.nil?
	
	headers.each_pair { |k,v|
		if 'content-type'==k.downcase.strip then
			res = v.first.downcase.strip.match(pattern)
			headers_charset = res[:charset].upcase if not res.nil?
		end
    }
    
    page_charset = headers_charset if page_charset.nil?
    page_charset = 'ISO-8859-1' if headers_charset.nil?

    puts "page_charset: #{page_charset}"

    page = page.encode(
		target_charset, 
		page_charset, 
		{ :replace => '_', :invalid => :replace, :undef => :replace }
	)

	page = page.gsub(pattern, "charset='UTF-8'")

	return page
end

def get_page(uri)
	puts "#{__method__}(#{uri})"

	data = load_page(uri: uri)

	return recode_page(
		data[:data],
		data[:headers],
	)
end

def get_image(uri)
	puts "#{__method__}(#{uri})"

	data = load_page(uri: uri)

	#~ return {
		#~ data: data[:data],
		#~ extension: 'jpg',
	#~ }
end


case ARGV.count
when 1
	uri = ARGV.first
else
	STDERR.puts "Usage: #{__FILE__} <uri>"
	exit 1
end

#page = get_page(uri)
#File.write('page.html',page)

#~ image = get_image(uri)
#~ File.write("image.#{image[:extension]}", image[:data])
