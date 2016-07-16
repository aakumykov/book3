# coding: utf-8

class RuWikipediaOrg < DefaultSite
	
	private

	def link_aliases
		{
			main_page: [
				'^https://ru\.wikipedia\.org$',
				'^https://ru\.wikipedia\.org/wiki/%D0%97%D0%B0%D0%B3%D0%BB%D0%B0%D0%B2%D0%BD%D0%B0%D1%8F_%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B0$',
			],		
			an_article: '/wiki/(?<title>[^/:]+)$',
			printable_article: '/w/index\.php\?title=(?<title>[^&=]+)&printable=yes',
		}.merge(super)
	end

	def rules
		{
			main_page: {
				processor: :MainPage,
				links: [ :an_article ]
			},
			an_article: {
				redirect: lambda { |uri| 
					title = uri.match(link_aliases[:an_article])[:title]
					"https://ru.wikipedia.org/w/index.php?title=#{title}&printable=yes"
				},
				processor: :AnArticle,
				links: [],
			},
			printable_article: {
				processor: :AnArticle,
				links: [],
			},
			any_page: {
				processor: :AnyPage,
				links: [],
			},
		}.merge(super)
	end
	
	def image_mode
		'white_black'
	end

	def image_whitelist
		[
			'//upload\.wikimedia\.org/wikipedia/commons/thumb/',
		]
	end
	
	def image_blacklist
		[
			'/15px-Commons-logo\.svg\.png$',
		]
	end
	
	def MainPage(dom)
		dom.search("//div[@id='content']")
	end

	def AnArticle(dom)
		#MainPage(dom)
		dom.search("//div[@id='content']")
		dom
	end
end
