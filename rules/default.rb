#coding: UTF-8

class DefaultSite
		
	def initialize(uri)
		#Msg::cyan "#{self.class}.#{__method__}('#{uri}')"
		
		@link_aliases = link_aliases.sort_by { |name,pattern| pattern.length }.reverse.to_h
		
		@page_rule = find_rule(uri)
			#Msg::debug " page_rule: #{@page_rule}"
		
		@filters = @page_rule[:filters] || []
		
		@image_whitelist = prepare_wb_list(image_whitelist)
		@image_blacklist = prepare_wb_list(image_blacklist)
		
		links_def = @page_rule[:links] || {}
		@links = links_def[:list] || []
		@links_limit = links_def[:limit] || nil
		
		@links_accepted = 0
			#Msg::debug "links_accepted: #{@links_accepted}"
	end

	def accept_link?(uri)
		#Msg::debug "#{self.class}.#{__method__}(#{uri}))"
		
		link_alias = uri2alias(uri)
		
		if @links_limit && @links_accepted >= @links_limit then
			return false
		else
			if @links.include?(link_alias) then
				@links_accepted += 1
				return true
			else
				return false
			end
		end
	end
	
	def accept_image?(src)
		black = !src.strip.match(@image_blacklist).nil?
		white = !src.strip.match(@image_whitelist).nil?
		
		case image_mode.to_sym
		when :black
			!black
		when :white
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
		
		if @page_rule.has_key?(:redirect) then
			new_uri = @page_rule[:redirect].call(uri)
				Msg::debug " программное перенаправлние на '#{new_uri}'"
			new_uri
		else
			uri
		end
	end

	def process_page(dom)
		# главный обработчик страницы
		self.send(@page_rule[:processor], dom)
			#Msg::cyan "страницу обрабатывает '#{self.class}.#{@page_rule[:processor]}()'"
		
		# фильтры страницы
		@filters.each { |filter_name|
			if self.class.private_method_defined?(filter_name) then
				self.send(filter_name,dom)
			else
				dom
			end
		}
		
		return dom
	end


	private
	
	def link_aliases
		{ 
			any_page: '^.+$',
		}
	end

	def rules
		{
			any_page: {
				processor: :AnyPage,
				links: {
					list: [],
				},
			},
		}
	end
	
	def image_mode
		'black'
	end
	
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

	
	## Служебные методы

	# методы-подготовщики
	def prepare_wb_list(list)
		list = list.flatten.sort_by{|pat| pat.length}.reverse
		list = list.map{|pat| Regexp.new(pat)}
		Regexp.union(list)
	end
		
	# методы-слуги
	def find_rule(uri)
		#Msg::debug "#{self.class}.#{__method__}(#{uri}, #{uri.class}))"
		
		link_alias = uri2alias(uri)
			Msg::info " #{link_alias}: #{uri}"
		
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
			return :any_page
		rescue => e
			name = e.message
				#Msg::debug " найдено правило '#{name}'"
			name.to_sym
		end
	end

	def name2rule(name)
		#Msg::debug "#{self.class}.#{__method__}('#{name}'))"
		
		rules[name.to_sym]
	end

	
	## Методы-обработчики

	# страничные методы
	def AnyPage(dom)
		dom.search('//body')
	end
	
	# фильтры
	def RemoveTag(dom,tag_name)
		dom.search("//#{tag_name}").each { |s|
			s.remove
		}
		return dom
	end
	
	def RemoveScripts(dom)
		Msg::debug "#{self.class}.#{__method__}())"
		
		RemoveTag(dom,'script')
	end
	
	def RemoveNoscripts(dom)
		Msg::debug "#{self.class}.#{__method__}())"
		
		RemoveTag(dom,'noscript')
	end
end
