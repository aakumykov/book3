# coding: utf-8

class OpennetRu < DefaultSite
	@@link_aliases = {
		main_page: '^http://opennet\.ru$',
		news_article: '/opennews/art\.shtml\?num=[0-9]+$',
		any_page: '^.+$'
	}

	@@rules = {
		main_page: {
			processor: :MainPage,
			links: [ :news_article ]
		},
		news_article: {
			processor: :NewsArticle,
			links: [],
		},
		any_page: {
			processor: :AnyPage,
			links: [],
		},
	}

	private
	
	def image_mode
		'blacklist'
	end
	
	def image_blacklist
		[
			super,
			'//opennet\.ru/banner\.gif',
			'//opennet\.ru/p\.gif',
			'//opennet\.ru/xml\.gif',
			'//opennet\.ru/twitter\.png',
			'//opennet\.ru/img/',
			'//opennet\.ru/img/',
			'//www\.gravatar\.com',
		]
	end
	

	def MainPage(dom)
		dom.search('//body//table')[2]
	end

	def NewsArticle(dom)
		dom.search("//form[@action='/cgi-bin/openforum/ch_cat.cgi']")
	end
end
