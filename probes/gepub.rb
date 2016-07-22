#!/usr/bin/env ruby
#coding: utf-8
system 'clear'

require 'gepub'
require 'fileutils'

builder = GEPUB::Builder.new {
  language 'en'
  unique_identifier 'http:/example.jp/bookid_in_url', 'BookID', 'URL'
  title 'GEPUB Sample Book'
  subtitle 'This book is just a sample'

  creator 'KOJIMA Satoshi'

  contributors 'Denshobu', 'Asagaya Densho', 'Shonan Densho Teidan', 'eMagazine Torutaru'

  date '2012-02-29T00:00:00Z'

  resources(:workdir => '/home/andrey/разработка/ruby/book3/probes/tmp/') {
#    cover_image 'img/image1.jpg' => 'image1.jpg'

  	  ordered {
	    file '1.html'
    	heading 'Chapter 1'

	    file '2.html'
    	heading 'Chapter 2'

		file '063636c2c8254b44bccc2baedaee9979.png'
		file '34e2e8aa9540ec3adbf83cfbbe03a55c.png'
		file '36d3c9a0a7aa52d8f220f4028fdad55b.png'
		file '37b80cf6bf32e8f2e168db3392246b53.png'
		file '5615e789c0cf14f79540511ffb5f48f1.png'
		file '738bfb26116af254fe66954b216cf599.png'
		file 'ab83b8fff73770c71a1aad60f5d27d2c.jpg'
		file 'c829e0f3184fa1d80d464ee9fed5477d.png'
		file 'd1873c5896da0387f719615b1094831b.gif'
		file 'd309f365c4faaa1b06908ff93fe8c79c.jpg'
		file 'e0566c5cd74ce5e1a06b0aed17d3b694.png'
		file 'f4a61ddc44782a507bdc78b8b9bb05df.png'
    }
  }
}
epubname = File.join(File.dirname(__FILE__), 'example_test_with_builder.epub')
builder.generate_epub(epubname)
