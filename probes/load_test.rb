#!/usr/bin/env ruby
# coding: utf-8

require 'uri'
require 'net/http'

def detectCharset(arg)
	puts "#{__method__}()"

    page = arg[:page]
    headers = arg.fetch(:headers,{})

    page_charset = nil
    headers_charset = nil

    pattern = Regexp.new(/charset\s*=\s*['"]?(?<charset>[^'"]+)['"]?/i)

    res = page.encode('UTF-8',{:replace => '_',:invalid => :replace,:undef => :replace}).match(pattern)
    page_charset = res[:charset].upcase if not res.nil?

    headers.each_pair { |k,v|
      if 'content-type'==k.downcase.strip then
        res = v.first.downcase.strip.match(pattern)
        headers_charset = res[:charset].upcase if not res.nil?
      end
    }

    return page_charset if headers_charset.nil?
    return headers_charset
    
    #~ return {
      #~ :headers_charset => headers_charset,
      #~ :page_charset => page_charset,
    #~ }
end

def load_page(uri)
	puts "#{__method__}()"

	redirects_limit = 3
	
	raise ArgumentError, 'слишком много перенаправлений' if redirects_limit == 0
	
	#uri = URI.escape(uri) if not uri.urlencoded?
	uri = URI(uri)

	data = {}

	Net::HTTP.start(uri.host, uri.port, :use_ssl => 'https'==uri.scheme) { |http|

	  request = Net::HTTP::Get.new(uri.request_uri)
	  request['User-Agent'] = 'Mozilla/5.0 (X11; Linux i686; rv:39.0) Gecko/20100101 Firefox/39.0'
	  
	  response = http.request request

	  case response
		when Net::HTTPRedirection then
			location = response['location']
			puts "перенаправление на '#{location}'"
			data =  self.work(
				:uri => location, 
				:redirects_limit => (redirects_limit-1)
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
  
  # перекодировка в UTF-8
  #charset = detectCharset(data)
  #puts "charset: #{charset}"
  # page = data[:page].encode(
  # 	'UTF-8', 
  # 	charset, 
  # 	{ :replace => '_', :invalid => :replace, :undef => :replace }
  # )
  
  return page
end

case ARGV.count
when 1
	uri = ARGV.first
else
	STDERR.puts "Usage: #{__FILE__} <uri>"
	exit 1
end

page = load_page(uri)

puts "page.class: #{page.class}"
puts "page.lines.count: #{page.lines.count}"
puts "page.size: #{page.size}"
puts "page.bytes.count: #{page.bytes.count}"

File.write('page.html',page)