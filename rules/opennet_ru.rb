#coding: UTF-8

class OpennetRu
	@@rules = {
		'^http://opennet\.ru$' => :MainPage,
		'/opennews/art\.shtml\?num=[0-9]+$' => :NewsArticle,
	}
	
	# инициализация
	def initialize
		@link_patterns = @@rules.keys.sort_by { |k| k.length }.reverse
		#Msg::debug "@link_patterns: #{@link_patterns}"
		#Msg::debug "@@rules: #{@@rules}"
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
	
	def get_processor(uri)
		Msg::debug("#{self.class}.#{__method__}(#{uri})", nobr: true)
		
		processor_name = nil
		
		begin
			@link_patterns.each { |pattern|
				#Msg::debug " #{uri}, (#{pattern})"
				raise pattern if uri.match(pattern)
			}
		rescue => e
			processor_name = @@rules[e.message]
			
				Msg::debug " -> processor_name: #{processor_name} (#{processor_name.class})"
		end
		
		processor_name
	end
	
	# "страничные" методы
	def MainPage(page)
		Msg::debug("#{self.class}.#{__method__}(page.size: #{page.size})")
	end
	
	def NewsArticle(page)
		Msg::debug("#{self.class}.#{__method__}(page.size: #{page.size})")
	end
end
