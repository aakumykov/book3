#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
system 'clear'

require 'gepub'
require 'fileutils'

book = GEPUB::Book.new
book.set_primary_identifier('http:/example.jp/bookid_in_url', 'BookID', 'URL')
book.language = 'ru'

# you can add metadata and its property using block
book.add_title('gepub test 2', nil, GEPUB::TITLE_TYPE::MAIN) {
  |title|
  title.lang = 'ru'
  title.file_as = 'gepub test 2 file_as'
  title.display_seq = 1
  title.add_alternates(
                       'jp' => 'gepub test 2 add_alternates (Japanese)',
                       'en' => 'gepub test 2 add_alternates (English)')
}
# you can do the same thing using method chain
book.add_title('これはあくまでサンプルです',nil, GEPUB::TITLE_TYPE::SUBTITLE).set_display_seq(1).add_alternates('en' => 'this book is just a sample.')
book.add_creator('Андрюха Кумыч') {
  |creator|
  creator.display_seq = 1
  creator.add_alternates('en' => 'Andrey Kumykov')
  creator.add_alternates('tr' => 'AHDPEi/l KYMblKOB')
}
book.add_contributor('OpennetRu').set_display_seq(1).add_alternates('ru' => 'Проект "Открытая сеть"')
book.add_contributor('Википедия').set_display_seq(2).add_alternates('en' => 'Wikipedia Russia')

File.open 'dragons_flight.jpg' do |io|
	book.add_item('images/dragons_flight.jpg',io).cover_image
end

Dir.glob('tmp/images/*') do |external_img|
	internal_img = external_img.gsub(/^[^\/]+\//,'')
	File.open(external_img) do |io|
		book.add_item(internal_img,io)
		#puts "добавление '#{external_img}' как '#{internal_img}'"
	end
end

# within ordered block, add_item will be added to spine.
book.ordered {
  book.add_item('text/wikipedia.xhtml').add_content('tmp/text/wikipedia.xhtml').toc_text('Википедия') 
  book.add_item('text/linux.xhtml').add_content(StringIO.new(File.read('tmp/text/linux.xhtml'))).toc_text('Линукс') # do not appear on table of contents
  book.add_item('tmp/text/opennet.xhtml').add_content(StringIO.new(File.read('tmp/text/opennet.xhtml'))).toc_text('OpenNET')
  # to add nav file:
  # book.add_item('path/to/nav').add_content(nav_html_content).add_property('nav')
}
epubname = File.join(File.dirname(__FILE__), 'example_test.epub')

# if you do not specify your own nav document with add_item, 
# simple navigation text will be generated in generate_epub.
# auto-generated nav file will not appear on spine.
book.generate_epub(epubname)

