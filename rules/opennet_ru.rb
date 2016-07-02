# coding: utf-8
system 'clear'

class OpennetRu
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
			processor: :DefaultPage,
			links: [],
		},
	}

	def initialize(uri)
		Msg::debug "#{self.class}.#{__method__}(#{uri}, #{uri.class}))"
		
		@current_rule = get_rule(uri)
			Msg::debug "@current_rule: #{@current_rule} (#{@current_rule.class})"
	
		@@link_aliases = @@link_aliases.sort_by { |name,pattern|
			pattern.length
		}.reverse.to_h
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
			#Msg::debug " link_name: #{link_name}"
		
		rule = name2rule(link_name)
			#Msg::debug " rule: #{rule}"
		
		return rule
	end
	
	def uri2name(uri)
		begin
			@@link_aliases.each_pair { |name,pattern|
				raise name.to_s if uri.match(pattern)
			}
		rescue => e
			e.message
		end
	end

	def name2rule(name)
		@@rules[name.to_sym]
	end

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


#o = OpennetRu.new('http://opennet.ru')
#puts o.accept_link?('http://opennet.ru')
#puts o.accept_link?('http://www.opennet.ru/opennews/art.shtml?num=44713')
