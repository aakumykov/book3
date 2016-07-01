#coding: UTF-8

class Default
	@@rules = {
		'^.+$' => :SomePage,
	}
	
	# инициализация
	def initialize
		
	end
	
	def accept_link?(uri)
		false
	end
	
	def get_processor(uri)		
		:SomePage
	end
	
	# "страничные" методы
	def SomePage(page)
		Msg::debug("#{self.class}.#{__method__}(page.size: #{page.size})")
		page
	end
end
