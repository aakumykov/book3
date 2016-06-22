#coding: UTF-8

class OpennetRu
	@@list = {
		'/' => :MainPage,
		'/opennews/art.shtml?num=[0-9]+$' => :NewsArticle,
	}
	
	def list
		@@list
	end
	
	def MainPage(page)
		Msg::debug("#{self.class}.#{__method__}()")
	end
	
	def NewsArticle(page)
		Msg::debug("#{self.class}.#{__method__}()")
	end
end
