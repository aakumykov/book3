#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'

require 'net/http'
require 'securerandom'

def uri2image_name(uri)
	#Msg::debug "#{__method__}('#{uri}')"

	f_name = uri.match(/(?<name>[-\w.]+)\.(?<ext>[a-z]+)$/i)
	
	if not f_name.nil? then
		name = f_name[:name].strip.downcase
		ext = f_name[:ext].strip.downcase
	else
		Msg::notice " ссылка без имени файла, запрашиваю HTTP-заголовок"
		uri = URI(uri)
		
		begin
			Net::HTTP.start(uri.host, uri.port, use_ssl:('https'==uri.scheme)) { |http|
				response = http.head(uri.request_uri)
				content_type = response.to_hash.fetch('content-type',['']).first
				ext = content_type.to_s.strip.match(/\/(?<ext>[a-z]+)$/i)
			}
		rescue => e
			ext = nil
		end
		
		if not ext.nil? then
			name = Digest::MD5.hexdigest(uri.to_s)
			ext = ext[:ext].strip.downcase.gsub('jpeg','jpg')
		else
			raise "неизвестный тип файла"
		end
	end
	
	f_name = name + '.' + ext
		#Msg::debug " имя файла: #{f_name}"
	
	return f_name
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
	
	def self.notice(msg)
		STDERR.puts "#{msg}"
	end
	
	def self.warning(msg)
		STDERR.puts "ВНИМАНИЕ: #{msg}"
	end
	
	def self.error(msg)
		STDERR.puts "ОШИБКА: #{msg}"
	end
end


#~ case ARGV.count
#~ when 1
	#~ uri = ARGV[0]
#~ else
	#~ STDERR.puts "Использование: #{__FILE__} <ссылка>"
	#~ exit 1
#~ end

#~ uri2image_name(uri)

Msg::info(uri2image_name 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Elvis_Presley_in_Jailhouse_Rock_1957.jpg/90px-Elvis_Presley_in_Jailhouse_Rock_1957.jpg')
Msg::info(uri2image_name 'https://login.wikimedia.org/wiki/Special:CentralAutoLogin/checkLoggedIn?wikiid=ruwiki&proto=https&type=1x1')
Msg::info(uri2image_name 'https://loginDHH.wikimedia.org/wiki/Special:CentralAutoLogin/checkLoggedIn?wikiid=ruwiki&proto=https&type=1x1')
