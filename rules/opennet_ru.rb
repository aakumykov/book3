#coding: UTF-8

class OpennetRu
	attr_reader :links

	@@rules = {
		'/opennews/art\.shtml\?num=[0-9]+$' => :NewsArticle,
	}
	
	def initialize
		@links = @@rules.keys.sort_by { |k| k.length }.reverse
	end
	
	def list
		@@rules
	end
	
	def MainPage(page)
		Msg::debug("#{self.class}.#{__method__}()")
	end
	
	def NewsArticle(page)
		Msg::debug("#{self.class}.#{__method__}()")
	end
end
