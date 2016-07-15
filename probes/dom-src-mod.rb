#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'

require 'nokogiri'

case ARGV.count
when 1
	file = ARGV.first
else
	STDERR.puts "Использование: #{__FILE__} <html_file>"
	exit 1
end

def remove_scripts(dom)
	dom.search('//script').each { |s|
		s.remove
	}
	return dom
end

def img2qwerty(file)
	dom = Nokogiri::HTML( File.open(file) )
		puts "dom: #{dom.class}"

	dom = remove_scripts(dom)

	dom.search('//img').each { |img|
		#puts "src: #{img[:src]}"
		img[:src] = 'qwerty.png'
	}

	dom.search('//img').each { |img|
		puts "src: #{img[:src]}"
		#img[:src] = 'qwerty.png'
	}

	return dom
end

dom = img2qwerty file

File.write("result-#{file}", dom.to_html)