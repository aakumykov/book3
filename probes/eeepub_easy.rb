#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'

require 'eeepub'

epub = EeePub::Easy.new do
  title 'sample'
  creator 'jugyo'
  identifier 'http://example.com/book/foo', :scheme => 'URL'
  uid 'http://example.com/book/foo'
end

epub.sections << [ '1.html', '2.html' ]

#~ text_dir = 'tmp/text'
#~ text = Dir.entries(text_dir)
#~ text.delete '.'
#~ text.delete '..'

#~ text.each do |txt|
	#~ text_file = File.join(text_dir,txt)
	#~ puts "text_file: #{text_file}" if File.exists? text_file
	#~ 
	#~ epub.sections << text_file
#~ end

#~ img_dir = 'tmp/images'
#~ images = Dir.entries(img_dir)
#~ images.delete '.'
#~ images.delete '..'
#~ 
#~ images.each do |img|
	#~ img_file = File.join(img_dir, img)
	#~ puts "image_file: #{img_file}" if File.exists? img_file
	#~ 
	#~ epub.assets << img_file
#~ end

epub.save('sample.epub')
