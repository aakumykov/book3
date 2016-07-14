#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'

require 'securerandom'

def uri2file_path(arg)
	mode = arg.keys.first
	data = arg.values.first.strip
	
	data_type = data.class
	
	raise ArgumentError "некорректный тип данных '#{data_type}'" if not [String,Hash].include?(data_type)
	raise ArgumentError "некорректный режим '#{mode}'" if not [:text,:image].include?(mode)
		
	:is_text = (:text == mode)
	:is_image = (:image == :mode)
		:is_headers = (Hash==data_type)
		:is_string = (String==data_type)
	
	dir = 'text_dir' if :is_text
	dir = 'image_dir' if :is_image
	
	name = uri
	
	ext_string = uri.match(/\.(?<ext>[a-z]+)$/i) if :is_string
	ext_string = data.fetch('content-type',['']).first.strip.match(/\.(?<ext>[a-z]+)$/i)
	
end

def u2p(arg)

	dir = 'text_dir'
	name = Digest::SHA256.hexdigest('uri')
	ext = 'html'

	file_path = File.join(dir,name + '.' + ext)
	
	ext = h2p(text: 'headers')
	ext = h2p(image: 'headers')
end

def h2p(arg)
	data = arg.match(/^(?<type>[a-z]+)\/(?<ext>[a-z]+)$/i)
	type = data[:type].downcase
	
	
	if 'text'==type then
		ext = 'html'
	elsif 'image'==type then
		ext = data[:ext].downcase
	else
		puts "неизвестный тип данных '#{type}'"
		return nil
	end
	
	return 
end

uri2file_path(text: 'http://opennet.ru/p.gif')
uri2file_path(image: 'http://opennet.ru/p.gif')
uri2file_path(text: {'content-mode'=>'image/png'})
uri2file_path(image: {'content-mode'=>'image/png'})

uri2file_path(text: nil)
uri2file_path(image: {})
uri2file_path(image: '')

