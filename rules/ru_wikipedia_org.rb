# coding: utf-8

class RuWikipediaOrg < DefaultSite
	@@link_aliases = {
		main_page: [
			'^https://ru\.wikipedia\.org$',
			'^https://ru\.wikipedia\.org/wiki/%D0%97%D0%B0%D0%B3%D0%BB%D0%B0%D0%B2%D0%BD%D0%B0%D1%8F_%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B0$',
		],
		an_article: '/wiki/[^/:]+$',
		any_page: '^.+$'
	}

	@@rules = {
		main_page: {
			processor: :MainPage,
			links: [ :an_article ]
		},
		an_article: {
			redirect: lambda { |uri| "#{uri}?printable=yes" },
			processor: :AnArticle,
			#links: [ ],
			links: [ :an_article ],
		},
		any_page: {
			processor: :AnyPage,
			links: [],
		},
	}
	
	private

	def MainPage(dom)
		dom.search("//div[@id='content']")
	end

	def AnArticle(dom)
		#MainPage(dom)
		dom.search("//div[@id='content']")
		dom
	end
end
