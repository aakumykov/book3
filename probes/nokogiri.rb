#!/usr/bin/env ruby
#coding: utf-8
system 'clear'

case ARGV.size
when 1
	file = ARGV.first.split('.')
	f_ext = file.pop
	f_name = file.join('.')
	file = ARGV.first
else
	STDERR.puts "Usage: #{__FILE__} <input file>"
	exit 1
end
#puts "FILE: #{file}, NAME: #{f_name}, EXT: #{f_ext}"

require 'nokogiri'

doc = Nokogiri::HTML( File.open(file) ) { |config|
	config.nonet
	config.noerror
	config.noent
}

doc.search('//script').remove


doc.search('//a').each { |a|
	puts a[:href]
}




#File.write("#{f_name}-result.#{f_ext}",doc.search("//form[@action='/cgi-bin/openforum/ch_cat.cgi']").inner_html)

