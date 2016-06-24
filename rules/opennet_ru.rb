#coding: UTF-8

class OpennetRu
	@@rules = {
		'/opennews/art\.shtml\?num=[0-9]+$' => :NewsArticle,
	}
	
	# инициализация
	def initialize
		@link_patterns = @@rules.keys.sort_by { |k| k.length }.reverse
	end
	
	def accept_link?(uri)
		accept = false
		
		begin
			@link_patterns.each { |pattern|
				raise 'match' if uri.match(pattern)
			}
		rescue
			accept = true
		end
		
		accept
	end
	
	def uri2rule(uri)
		
	end
	
	# "страничные" методы
	def MainPage(page)
		Msg::debug("#{self.class}.#{__method__}()")
	end
	
	def NewsArticle(page)
		Msg::debug("#{self.class}.#{__method__}()")
	end
end
