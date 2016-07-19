#!/usr/bin/env ruby
#coding: utf-8
system 'clear'

require 'gepub'

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


builder = GEPUB::Builder.new {
  language 'en'
  unique_identifier 'http:/example.jp/bookid_in_url', 'BookID', 'URL'
  title 'GEPUB Sample Book'
  subtitle 'This book is just a sample'

  creator 'KOJIMA Satoshi'

  contributors 'Denshobu', 'Asagaya Densho', 'Shonan Densho Teidan', 'eMagazine Torutaru'

  date '2012-02-29T00:00:00Z'

  resources(:workdir => source_dir) {
    #cover_image 'img/image1.jpg' => 'image1.jpg'
   ordered {
      file 'text/1.html'
      heading 'Chapter 1'

      file 'text/2.html'
      #heading 'Chapter 2'

      file 'text/3.html'
      heading 'Chapter 3'
   }
  }
}
epubname = File.join(File.dirname(__FILE__), 'test2.epub')
builder.generate_epub(epubname)


