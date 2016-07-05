# coding: utf-8
system 'clear'

class RuWikipediaOrg
	@@link_aliases = {
		main_page: [
			'^https://ru.wikipedia\.org$',
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
			processor: :AnArticle,
			links: [ :an_article ],
		},
		any_page: {
			processor: :DefaultPage,
			links: [],
		},
	}

	def initialize(uri)
		Msg::debug "#{self.class}.#{__method__}(#{uri}, #{uri.class}))"
		
		@current_rule = get_rule(uri)
			#Msg::debug "@current_rule: #{@current_rule} (#{@current_rule.class})"
	
		@@link_aliases = @@link_aliases.sort_by { |name,pattern| pattern.length }.reverse.to_h
	end

	def accept_link?(uri)
		#Msg::debug "#{self.class}.#{__method__}(#{uri}))"
		
		link_name = uri2name(uri)
			#Msg::debug "link_name: #{link_name}"
		
		@current_rule[:links].include?(link_name.to_sym)
	end

	def process_page(page)
		self.send(@current_rule[:processor], page)
	end


	private

	# Служебные методы
	def get_rule(uri)
		Msg::debug "#{self.class}.#{__method__}(#{uri}, #{uri.class}))"
		
		link_name = uri2name(uri)
			Msg::debug " link_name: #{link_name}"
		
		rule = name2rule(link_name)
			#Msg::debug " rule: #{rule}"
		
		return rule
	end
	
	def uri2name(uri)
		Msg::debug "#{self.class}.#{__method__}(#{uri}))"
		
		begin
			@@link_aliases.each_pair { |name,pattern|
				raise name.to_s if uri.match( Regexp.union(pattern) )
			}
			
				Msg::error "не найдено ни одного правила"
			
			return 'any_page'
		rescue => e
			name = e.message
				Msg::debug " name in rescue: #{name} (#{name.class})"
			name
		end
	end

	def name2rule(name)
		@@rules[name.to_sym]
	end

	# Страничные методы
	def DefaultPage(dom)
		dom.search('//body')
	end

	def MainPage(dom)
		dom.search("//div[@id='content']")
	end

	def AnArticle(dom)
		#MainPage(dom)
		dom.search("//div[@id='content']").search("//table[@class='navbox']").remove
		dom.search("//div[@id='mw-navigation']").remove
		dom
	end
end


#o = OpennetRu.new('http://opennet.ru')
#puts o.accept_link?('http://opennet.ru')
#puts o.accept_link?('http://www.opennet.ru/opennews/art.shtml?num=44713')
