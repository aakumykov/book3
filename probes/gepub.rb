#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
system 'clear'

require 'gepub'
require 'fileutils'

case ARGV.count
when 1
	source_dir = ARGV.first
	workdir = File.dirname( File.expand_path(__FILE__) )
else
	$stderr.puts "Использование: #{__FILE__} <каталог-источник>"
	exit 1
end

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
		 'en' => 'gepub test 2 add_alternates (English)'
	)
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

#~ File.open 'dragons_flight.jpg' do |io|
	#~ book.add_item('images/dragons_flight.jpg',io).cover_image
#~ end

# within ordered block, add_item will be added to spine.
Dir.chdir(source_dir) and puts "текущий каталог: #{Dir.pwd}"

book.ordered {

	Dir.glob("text/*") do |txt_file|
		book.add_item(txt_file).add_content(txt_file).toc_text(File.basename(txt_file))
		puts "добавлен текст '#{txt_file}'"
		# to add nav file:
		# book.add_item('path/to/nav').add_content(nav_html_content).add_property('nav')
	end

	Dir.glob('images/*') do |img_file|
		File.open(img_file) do |io|
			book.add_item(img_file,io)
			puts "добавлена картинка '#{img_file}'"
		end
	end
}

Dir.chdir(workdir) and puts "текущий каталог: #{Dir.pwd}"

epubname = File.join(File.dirname(__FILE__), 'example_test.epub')
puts "имя EPUB-файла: #{epubname}"

# if you do not specify your own nav document with add_item, 
# simple navigation text will be generated in generate_epub.
# auto-generated nav file will not appear on spine.
book.generate_epub(epubname)

puts "ГОТОВО!" if File.exists? epubname