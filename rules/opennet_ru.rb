# coding: utf-8

class OpennetRu
	@@link_names = {
		main_page: '^http://opennet\.ru$',
		news_article: '/opennews/art\.shtml\?num=[0-9]+$',
		any_page: '^.+$'
	}

	@@rules = {
		main_page: {
			news_article: :NewsArticle,
			main_page: :MainPage,
		},
		news_article: {
		},
		any_page: {
			any_page: :DefaultPage,
		},
	}

	def initialize
		link_names = @@link_names.sort_by { |name,pattern|
			pattern.length
		}.reverse.to_h
		
		#puts "#{link_names}"
		#link_names.each { |k,v| puts "#{k} => #{v}"}
	end

	def accept_link?(uri)
		
	end


	private

	# Страничные методы
	def DefaultPage(dom)
		dom.search('//body').to_html
	end

	def MainPage(dom)
		dom.search('//body//table')[2].to_html
	end

	def NewsArticle(dom)
		dom.search("//form[@action='/cgi-bin/openforum/ch_cat.cgi']").inner_html
	end
end


o = OpennetRu.new
