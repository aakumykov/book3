#!/usr/bin/env ruby
# coding: utf-8

require 'uri'
require 'net/http'

# 
def load_data(arg)
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
				:page => response.body,
			}
		else
			response.value
		end
	}
  
  return data
end

def recode_page(page, headers, target_charset='UTF-8')
	puts "#{__method__}()"
	puts "========== Headers: =========="
	headers.each_pair { |k,v| puts "#{k}: #{v}" }
	puts "=========================="

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

# def detect_file_name(uri, headers)
# 	content_type = headers.fetch('content-type',[nil]).first.match(/[a-z]+\/[a-z+]+/i).to_s
		
# 		#puts "content_type: #{content_type}"
	
# 	f_name = uri.match(/\/([^\/]+)\.([a-z]+)$/)[1]
# 	f_ext = content_type.match(/\/([a-z]+)$/)[1]
	
# 		#puts "f_name: #{f_name}"
# 		#puts "f_ext: #{f_ext}"
	
# 	file_name = "#{f_name}.#{f_ext}"
# end

def get_page(uri)
	puts "#{__method__}(#{uri})"

	data = load_data(uri: uri)

	return recode_page(
		data[:data],
		data[:headers],
	)
end

def get_image(uri)
	puts "#{__method__}(#{uri})"

	data = load_data(uri)

	content_type = data[:headers].fetch('content-type',[nil]).first.match(/[a-z]+\/[a-z+]+/i).to_s
	
		puts "content_type: #{content_type}"
	
	f_name = uri.match(/\/([^\/]+)\.([a-z]+)$/)[1]
	f_ext = content_type.match(/\/([a-z]+)$/)[1]
	
		puts "f_name: #{f_name}"
		puts "f_ext: #{f_ext}"
	
	file_name = "#{f_name}.#{f_ext}"

	# MIME type определять самому!
	return {
		data: data[:data],
		type: content_type,
	}
end


case ARGV.count
when 1
	uri = ARGV.first
else
	STDERR.puts "Usage: #{__FILE__} <uri>"
	exit 1
end

data = get_page(uri)

page = data[:data]
puts "page.class: #{page.class}"
puts "page.lines.count: #{page.lines.count}"
puts "page.size: #{page.size}"
puts "page.bytes.count: #{page.bytes.count}"

File.write(data[:file_name],data[:data])
