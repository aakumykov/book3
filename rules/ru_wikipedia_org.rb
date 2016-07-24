# coding: utf-8

class RuWikipediaOrg < DefaultSite
	
	private

	def link_aliases
		title_pattern = '?<title>[^/:?=]+'
		{
			#~ main_page: [
				#~ '^http[s]?://ru\.wikipedia\.org$',
				#~ '^http[s]?://ru\.wikipedia\.org/wiki/%D0%97%D0%B0%D0%B3%D0%BB%D0%B0%D0%B2%D0%BD%D0%B0%D1%8F_%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B0$',
			#~ ],
			main_page: '^http[s]?://ru\.wikipedia\.org/wiki/%D0%97%D0%B0%D0%B3%D0%BB%D0%B0%D0%B2%D0%BD%D0%B0%D1%8F_%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B0$',
			an_article: '^http[s]?://ru\.wikipedia\.org/wiki/('+title_pattern+')$',
			printable_article: '^http[s]?://ru\.wikipedia\.org/w/index\.php\?title=('+title_pattern+')&printable=yes',
		}.merge(super)
	end

	def rules
		{
			main_page: {
				processor: :MainPage,
				filters: [ 
					:RemoveScripts, 
					:RemoveNoscripts, 
					:RemoveNavigation 
				],
				links: {
					list: [ :an_article ],
				},
			},
			an_article: {
				redirect: lambda { |uri| 
					title = uri.match(link_aliases[:an_article])[:title]
					"https://ru.wikipedia.org/w/index.php?title=#{title}&printable=yes"
				},
			},
			printable_article: {
				processor: :PrintableArticle,
				filters: [ 
					:RemoveScripts, 
					:RemoveNoscripts, 
					:RemoveNavigation 
				],
				links: {
					list: [:an_article ],
					limit: 5,
				}
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

	def PrintableArticle(dom)
		#MainPage(dom)
		dom.search("//div[@id='content']")
		return dom
	end
	
	# страничные фильтры
	def RemoveNavigation(dom)
		[
			"//div[@id='mw-navigation']",
			"//table[@class='navbox']",
			"//table[contains(@class,'navigation-box')]",
			
			"//div[@id='mw-hidden-catlinks']",
			"//div[@id='mw-normal-catlinks']",	
			
			"//*[@id='footer-places']",
			"//*[@id='footer-icons']",
			
			"//span[@class='mw-editsection']",
			
			"//div[@class='mw-indicators']",
		].each { |xpath|
			dom.search(xpath).remove
		}
		
		return dom
	end
end
