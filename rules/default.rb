#coding: UTF-8

class DefaultSite
	def link_aliases
		{ 
			any_page: '^.+$',
		}
	end

	def rules
		{
			any_page: {
				processor: :AnyPage,
				links: [],
			},
		}
	end
		
	def initialize(uri)
		#Msg::debug "#{self.class}.#{__method__}('#{uri}')"
		
		@link_aliases = link_aliases.sort_by { |name,pattern| pattern.length }.reverse.to_h
		
		@rules = rules
		
		@current_rule = get_rule(uri)
				
		@image_whitelist = prepare_filter(image_whitelist)
			
		@image_blacklist = prepare_filter(image_blacklist)
	end

	def accept_link?(uri)
		#Msg::debug "#{self.class}.#{__method__}(#{uri}))"
		
		link_alias = uri2alias(uri)
			Msg::debug "link_alias: #{link_alias} (#{uri})"
		
		@current_rule[:links].include?(link_alias.to_sym)
	end
	
	def accept_image?(src)
		black = !src.strip.match(@image_blacklist).nil?
		white = !src.strip.match(@image_whitelist).nil?
		
		case image_mode.to_sym
		when :blacklist
			!black
		when :whitelist
			white
		when :white_black
			white && !black
		when :black_white
			(black && white) || !black
		else
			raise "неизвестный режим приёма картинок '#{@@image_mode}'"
		end
	end

	def redirect(uri)
		#Msg::debug("#{self.class}.#{__method__}(#{uri})")
		
		if @current_rule.has_key?(:redirect) then
			new_uri = @current_rule[:redirect].call(uri)
				Msg::notice " программное перенаправлние на '#{new_uri}'"
			new_uri
		else
			uri
		end
	end

	def process_page(page)
		self.send(@current_rule[:processor], page)
	end

	


	private
	
	def image_whitelist
		[ '.*' ]
	end
	
	def image_blacklist
		[
			#'//data:image/',
			'//top\.mail\.ru',
			'//top-[^.]+\.mail\.ru',
			'//counter\.rambler\.ru',
			'//[^.]+\.gravatar\.com',
		]
	end

	# Служебные методы
	def prepare_filter(list)
		list = list.flatten.sort_by{|pat| pat.length}.reverse
		list = list.map{|pat| Regexp.new(pat)}
		Regexp.union(list)
	end
	
	def get_rule(uri)
		#Msg::debug "#{self.class}.#{__method__}(#{uri}, #{uri.class}))"
		
		link_alias = uri2alias(uri)
			Msg::debug " псевдоним сылки: #{link_alias}"
		
		rule = name2rule(link_alias)
			#Msg::debug " правило: #{rule}"
		
		return rule
	end
	
	def uri2alias(uri)
		#Msg::debug "#{self.class}.#{__method__}(#{uri}))"
		
		begin
			@link_aliases.each_pair { |name,pattern|
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
		Msg::debug "#{self.class}.#{__method__}('#{name}'))"
		
		@rules[name.to_sym]
	end

	# Страничные методы
	def AnyPage(dom)
		dom.search('//body')
	end
end
