#coding: UTF-8

class DefaultSite
	@@link_aliases = {
		any_page: '^.+$'
	}

	@@rules = {
		'^.+$' => :AnyPage,
	}
	
	def initialize(uri)
		#Msg::debug "#{self.class}.#{__method__}(#{uri}, #{uri.class}))"
		
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

	def redirect(uri)
		#Msg::debug("#{self.class}.#{__method__}(#{uri})")
		
		if @current_rule[:redirect].nil? then
			uri
		else
			new_uri = @current_rule[:redirect].call(uri)
				Msg::debug " программное перенаправлние на '#{new_uri}'"
			new_uri
		end
	end

	def process_page(page)
		self.send(@current_rule[:processor], page)
	end


	private

	# Служебные методы
	def get_rule(uri)
		#Msg::debug "#{self.class}.#{__method__}(#{uri}, #{uri.class}))"
		
		link_alias = uri2name(uri)
			Msg::debug " псевдоним сылки: #{link_alias}"
		
		rule = name2rule(link_alias)
			#Msg::debug " правило: #{rule}"
		
		return rule
	end
	
	def uri2name(uri)
		#Msg::debug "#{self.class}.#{__method__}(#{uri}))"
		
		begin
			@@link_aliases.each_pair { |name,pattern|
				pattern = [pattern] if not pattern.is_a? Array				
				pattern = Regexp.union( pattern.map { |p| Regexp.new(p) } )
				raise name.to_s if uri.match(pattern)
			}
			
			Msg::error "не найдено ни одного правила"
			
			return 'any_page'
		rescue => e
			name = e.message
				#Msg::debug " найдено правило '#{name}'"
			name
		end
	end

	def name2rule(name)
		@@rules[name.to_sym]
	end

	# Страничные методы
	def AnyPage(dom)
		dom.search('//body')
	end
end
