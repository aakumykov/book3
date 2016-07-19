#!/usr/bin/env ruby
#coding: utf-8
system 'clear'

require 'eeepub'

def show_usage
	STDERR.puts "Использование: #{__FILE__} <каталог-источник>"
	exit 1
end

case ARGV.count
when 1
	source_dir = ARGV.first
else
	show_usage
	exit 1
end


epub = EeePub.make do
  title       'sample'
  creator     'jugyo'
  publisher   'jugyo.org'
  date        '2010-05-06'
  identifier  'http://example.com/book/foo', :scheme => 'URL'
  uid         'http://example.com/book/foo'

  files [
	"#{source_dir}/text/1.html",
	"#{source_dir}/text/2.html",
	"#{source_dir}/text/3.html",
	]
  nav [
    {:label => 'Linux', :content => '1.html', :nav => [
      {:label => 'Unix', :content => '1.html#Unix'}
    ]},
    {:label => 'Википедия', :content => '2.html'},
    {:label => 'Opennet', :content => '3.html'},
  ]
end
epub.save('test3.epub')