#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
system 'clear'

require 'nokogiri'

def show_error msg=''
	$stderr.puts "ОШИБКА: #{msg}" if not msg.empty?
	$stderr.puts "Использование: #{__FILE__} <src_mode: xml|html> <dst_mode: html|xml|xhtml> <file>"
	exit 1
end

case ARGV.count
when 3
	src_mode = ARGV.first
	dst_mode = ARGV[1]
	file = ARGV.last
else
	show_error
end

puts "#{src_mode} --> #{dst_mode}"

data = File.read(file)

case src_mode
when 'html'
	doc = Nokogiri::HTML(data)
when 'xml'
	doc = Nokogiri::XML(data)
else
	show_error "некорректный входной режим '#{src_mode}"
end

name="#{file.split('.').first}-#{src_mode}2#{dst_mode}"

case dst_mode
when 'html'
	dst_file = "#{name}.html"
	File.write(dst_file, doc.to_html)
	puts "записан файл '#{dst_file}"
when 'xhtml'
	dst_file = "#{name}.xhtml"
	File.write(dst_file, doc.to_xhtml)
	puts "записан файл '#{dst_file}"
when 'xml'
	dst_file = "#{name}.xml"
	File.write(dst_file, doc.to_xml)
	puts "записан файл '#{dst_file}"
else
	show_error "некорректный выходной режим '#{dst_mode}'"
end
