
class OpennetRu
	@@link_names = {
		main_page: '^http://opennet\.ru$',
		news_article: '/opennews/art\.shtml\?num=[0-9]+$',
		unknown_page: '^.+$'
	}

	@@rules = {
		main_page: {
			news_article: :NewsArticle,
			main_page: :MainPage,
		},
		news_article: {
		},
		unknown_page: {
			
		},
	}

	def DefaultPage
	end

	def MainPage
	end

	def NewsArticle
	end
end

