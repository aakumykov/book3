#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'

require 'sqlite3'
require 'net/http'
require 'nokogiri'
require 'securerandom'
require 'colorize'

class Book
	# пользовательское
	attr_reader :title, :author, :language
	attr_accessor :page_limit, :error_limit, :depth_limit
	
	# внутреннее
	attr_accessor :page_count
	attr_reader :text_dir, :images_dir, :contacts

	@@db_name = 'links.sqlite3'
	@@table_name = 'table1'
	
	@@rules_dir = 'rules'
	@@work_dir = 'tmp'
	
	@@contacts_file = 'contacts4header.txt'
	
	@@threads_count = 3

	def initialize
		Msg::debug("#{self.class}.#{__method__}()")
	
		@title = 'Новая книга'
		@author = 'Неизвестный автор'
		@language = 'ru'
		
		# Для скачивания Википедии в заголовок необходимо вставлять контактную информацию
		raise "Не найден файл контактов (#{@@contacts_file})" if ! File.exists?(@@contacts_file)
		@contacts = File.read(@@contacts_file)

		@source = []

		@page_limit = 0
		@error_limit = 5
		@depth_limit = 0

		@page_count = 0
		@error_count = 0
		@depth = 0
		
		@threads_count = 3
		
		# настройка БД
		@@db = SQLite3::Database.new @@db_name
		@@db.execute("PRAGMA journal_mode = OFF")

		@@db.execute("DROP TABLE IF EXISTS #{@@table_name}")
		@@db.execute("
			CREATE TABLE #{@@table_name} (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				parent_id INTEGER,
				status VATCHAR(20) DEFAULT 'new',
				uri TEXT,
				title TEXT,
				file TEXT
			)"
		)
		
		# каталоги
		if not Dir.exists?(@@work_dir) then
			Dir.mkdir(@@work_dir) or raise "невозможно создать каталог #{@@work_dir}"
		end
		
		@text_dir = File.join(@@work_dir,'text')
		
		if not Dir.exists?(@text_dir) then
			Dir.mkdir(@text_dir) or raise "невозможно создать каталог #{@text_dir}"
		end
		
		@image_dir = File.join(@@work_dir,'images')
		
		if not Dir.exists?(@image_dir) then
			Dir.mkdir(@image_dir) or raise "невозможно создать каталог #{@image_dir}"
		end
	end


	def title=(a_title)
		raise 'некорректное название книги' if a_title.strip.empty?
		@title = a_title
	end

	def author=(an_author)
		raise 'некорректное имя автора' if an_author.strip.empty?
		@author = an_author
	end

	def language=(a_language)
		a_language.strip!
		raise 'некорректный язык книги' if not a_language.match(/^[a-z]{2}$/)
		@language = a_language
	end


	def threads=(n)
		@@threads_count = n if n.to_i.to_s==n.to_s
	end
	

	def add_source(uri)
		#Msg::debug("#{self.class}.#{__method__}(#{arg})")
		link_add(0,uri)
	end

	def prepare
		Msg::debug("#{self.class}.#{__method__}()")

		until prepare_complete? do
			
			Msg::debug '-'*20

			threads = []
			
			links = get_fresh_links
				Msg::debug "Ссылок на цикл: #{links.count}"
			
			links.each do |row|
				id, uri = row
				threads << Thread.new {
					Processor.new(self, id, uri).work
				}
			end
			
			threads.each { |thr| 
				begin
					id = thr.value
					link_update(
						set: { status: 'processed' },
						where: { id: id }
					)
					@page_count += 1
				rescue => e
					@error_count += 1
					Msg::error e.class, e.message, e.backtrace
				end
			}
		end
		
		puts "Подготовка завершена"
	end

	def prepare_complete?
		Msg::debug("#{self.class}.#{__method__}", nobr: true)

			Msg::debug(", pages: #{@page_count}/#{@page_limit}, errors: #{@error_count}/#{@error_limit}, depth: #{@depth}/#{@depth_limit}")

		if 0==get_fresh_links.count then
			Msg::info "закончились ссылки"
			return true
		end
		
		if @page_count >= @page_limit then
			Msg::info "все страницы (#{@page_count} шт) обработаны"
			return true
		end
		
		if @error_count >= @error_limit then
			Msg::info "достигнут предел количества ошибок (#{@error_count})"
			return true
		end
		
		if @depth > @depth_limit then
			Msg::info "достигнут предел глубины (#{@depth}))'"
			return true
		end
	end

	def save
		Msg::debug("#{self.class}.#{__method__}()")
	end
	
	def get_fresh_links
		Msg::debug("#{self.class}.#{__method__}()")
		@@db.execute("SELECT id, uri FROM #{@@table_name} WHERE status='new' LIMIT #{@@threads_count}")
	end

	def get_rule(uri)
		#Msg::debug("#{self.class}.#{__method__}(#{uri})")
		
		require "./#{@@rules_dir}/default.rb" if not Object.const_defined? :DefaultSite
		
		host = URI(uri).host
		file_name = host.gsub('.','_') + '.rb'
		class_name = host.split('.').map{|c| c.capitalize }.join
		
			#Msg::debug(" host: #{host}, file_name: #{file_name}, class_name: #{class_name}")
		
		case host
		when 'opennet.ru'
			require "./#{@@rules_dir}/#{file_name}"
			rule = Object.const_get(class_name).new(uri)
		when 'ru.wikipedia.org'
			require "./#{@@rules_dir}/#{file_name}"
			rule = Object.const_get(class_name).new(uri)
		else
			require "./#{@@rules_dir}/default.rb"
			rule = Object.const_get(:Default).new(uri)
		end
	end

	def link_add(parent_id,uri)
		#Msg::debug("#{self.class}.#{__method__}(#{parent_id}, #{uri})")
		
		@@db.execute(
			"INSERT INTO #{@@table_name} (parent_id, uri) VALUES (?, ?)",
			parent_id,
			uri
		)
	end

	# link_update({key:value [,key:value]},{key:value [,key:value]}
	def link_update(params)
		#Msg::debug("#{self.class}.#{__method__}(#{params})")
		
		condition = params[:where]
		data = params[:set]
		
		condition = condition.to_a.map { |k,v| 
			v="'#{v}'" if v.is_a? String
			"#{k}=#{v}" 
		}.join(' AND ')
		
		data = data.to_a.map { |k,v| 
			v="'#{v}'" if v.is_a? String
			"#{k}=#{v}" 
		}.join(', ')
		
		sql = "UPDATE #{@@table_name} SET #{data} WHERE #{condition}"
			#Msg::debug("#{self.class}.#{__method__}(), #{sql}")
		
		@@db.execute(sql)
	end

	# arg = {mode_name: uri}
	def uri2file_path(arg={})
		mode = arg.keys.first
		uri = arg.values.first
		
		case mode
		when :text
			dir = @text_dir
			name = uri
			ext = 'html'
		when :image
			dir = @image_dir
			name = uri
			if arg.has_key?(:headers) then
				ext = headers2ext(arg[:headers])
			else
				ext=uri.match(/\.(?<ext>[a-z]+)$/i)[:ext]
			end
		else
			raise ArgumentError "неизвестный режим '#{mode}'"
		end
		
		file_name = Digest::MD5.hexdigest(name) + '.' + ext.downcase
		file_path = File.join(dir, file_name)
			
			#Msg::debug " file_path: #{file_path}"
		
		return file_path
	end
	
	
	private
		
	class Processor
		
		def initialize(book, id, uri)
			#Msg::debug("#{self.class}.#{__method__}(#{id}, #{uri})")
			
			the_uri = URI(uri)
			
			@book = book
			
			@current_id = id
			@current_uri = uri
			@current_host = the_uri.host
			@current_scheme = the_uri.scheme
			@current_rule = @book.get_rule(@current_uri.to_s)
				#Msg::debug " @current_rule: #{@current_rule}"
			
			@file_path = @book.uri2file_path(text: @current_uri)
			@file_name = File.basename(@file_path)

				#Msg::debug(" rule: #{@current_rule.class}")
		end
		
		def work
			Msg::debug("#{self.class}.#{__method__}()")
			
			@page = get_page(@current_uri)
			@title = get_title(@page)
			
			result_page = @current_rule.process_page(@page)
				
			links_hash = collect_links(result_page)
			
			result_page = make_links_offline(links_hash, result_page)
			
			result_page = load_images(result_page)
			#load_images # переделать в будущем так?
			
			save_page(@title,result_page)
			
			return @current_id
		end
		
		def get_page(uri)
			Msg::debug("#{self.class}.#{__method__}(#{uri})")
			
			uri = @current_rule.redirect(uri)
			
			data = download(uri: uri)
			
			page = recode_page(data[:data], data[:headers])
				#Msg::debug " страница: #{page.lines.count} строк, #{page.bytes.count} байт"
				#File.write('page2.html', page)
			
			page = Nokogiri::HTML(page) { |config|
				config.nonet
				config.noerror
				config.noent
			}
				#File.write('page3.html', page.to_html)
			
			page
		end
		
		def get_image(uri)
			#Msg::debug("#{self.class}.#{__method__}(#{uri})")

			res = download(uri: uri)
		end
		
		def download(arg)
			#Msg::debug ''
			
			uri = URI(arg[:uri])
			mode = arg.fetch(:mode,:full).to_s
			redirects_limit = arg[:redirects_limit] || 10	# опасная логика...
			
			Msg::info("#{self.class}.#{__method__}('#{uri}', mode: #{mode})")
			
				#Msg::debug " uri: #{uri}"
				#Msg::debug " mode: #{mode}"
				#Msg::debug " redirects_limit: #{redirects_limit}"
			
			if 0==redirects_limit then
				Msg::warning " слишком много пененаправлений"
				return nil
			end

			http = Net::HTTP.start(
				uri.host, 
				uri.port, 
				:use_ssl => ('https'==uri.scheme)
			)

			case mode
			when 'headers'
				#Msg::debug "РЕЖИМ СКАЧИВАНИЯ: #{mode}"
				request = Net::HTTP::Head.new(uri.request_uri)
			else
				request = Net::HTTP::Get.new(uri.request_uri)
			end

			#request['User-Agent'] = @book.user_agent
			request['User-Agent'] = "Mozilla/5.0 (X11; Linux i686; rv:39.0) Gecko/20100101 Firefox/39.0 [TestCrawler (admin@kempc.edu.ru)]"


			response = http.request(request)

			case response
			when Net::HTTPRedirection then
				location = response['location']
					Msg::notice " перенаправление на '#{location}'"
				
				result =  send(__method__, {
					uri: location, 
					mode: mode,
					redirects_limit: (redirects_limit-1),
				})
			when Net::HTTPSuccess then
				
					#Msg::debug "response keys: #{response.to_hash.keys}"
			
				result = {
					:data => response.body.to_s,
					:headers => response.to_hash,
				}
				
				if 'headers'==mode then
					return result[:headers]
				else
					return result
				end
			else
				Msg::warning " неприемлемый ответ сервера: '#{response.value}"
				return nil
			end
		end
		
		def load_images(dom)
			Msg::debug("#{self.class}.#{__method__}()")
			
			dom.search("//img").each { |img|
				
				uri = repair_uri(img[:src])
				
				if ! @current_rule.accept_image?(uri) then
					#Msg::notice "отбрасываю картинку '#{uri}'"
					next
				end
				
				# определяю имя файла для картинки
				begin
					# сначала по URI
					file_path = @book.uri2file_path(image: uri)
				rescue
					begin
						# если не вышло, с привлечением заголовков
						headers = download(uri: uri, mode: 'headers')
						file_path = @book.uri2file_path(image: uri, headers: headers)
					rescue => e
						Msg::warning "не удалось получить имя файла для картинки '#{uri}'", e
						next
					end
				end
				
				# проверяю, загружено ли уже
				if File.exists?(file_path) then
					Msg::debug "картинка '#{uri}' уже загружена (#{file_path})"
					next
				end
				
				# скачиваю картинку
				begin
					data = download(uri: uri)
				rescue => e
					Msg::warning "не удалось загрузить картинку '#{uri}' (#{e.message})"
					next
				end
				
				# сохраняю картинку в файл
				begin
					File.write(file_path, data[:data])
					img[:src] = file_path
				rescue => e
					Msg::warning "не удалось записать картинку '#{uri}' в файл '#{file_path}'"
					next
				end
			}
			
			return dom
		end
		
		def get_title(dom)
			#Msg::debug("#{self.class}.#{__method__}()")
			
			title = dom.search('//title').text
				#Msg::debug " title: #{title}"
			return title
		end
	
		def collect_links(dom)
			Msg::debug("#{self.class}.#{__method__}()")
			
			links = dom.search('//a').map { |a| a[:href] }.compact
			links = links.map { |lnk| lnk.strip }
			links = links.delete_if { |lnk| '#'==lnk[0] || lnk.empty? }
				
				Msg::debug " всего ссылок: #{links.count}"
			links = links.uniq
				Msg::debug " уникальных: #{links.count}"
			
			links_hash = links.map { |lnk| 
				#Msg::debug "lnk: #{lnk}"
				begin
					[lnk, repair_uri(lnk)]
				rescue => e
					Msg::notice "ОТБРОШЕНА КРИВАЯ ССЫЛКА: #{lnk}"
					nil
				end
			}.compact.to_h
			
				Msg::debug(" восстановленно: #{links_hash.count}")
			
			links_hash = links_hash.keep_if { |lnk_orig,lnk_full| 
				@current_rule.accept_link?(lnk_full) 
			}
			
				Msg::debug(" оставлено: #{links_hash.count}")
			
			links_hash.each_pair { |lnk_orig,lnk_full| 
				@book.link_add(@current_id, lnk_full) 
			}
			
			return links_hash
		end
		
		def make_links_offline(links_hash, page)
			Msg::debug("#{self.class}.#{__method__}()")
			
			page.search("//a").map { |a|
				links_hash.each_pair { |lnk_orig,lnk_full|
					if a[:href]==lnk_orig then
						lnk_local = @book.uri2file_path(text: lnk_full) 
							#Msg::debug "локализация ссылки '#{lnk_orig}' -> '#{lnk_local}'"
						a[:href] = lnk_local
					end
				}
			}
			
			page
		end

		def recode_page(page, headers, target_charset='UTF-8')
			Msg::debug("#{self.class}.#{__method__}()")
			
			page_charset = nil
			headers_charset = nil
			
			pattern_big=Regexp.new(/<\s*meta\s+http-equiv\s*=\s*['"]\s*content-type\s*['"]\s*content\s*=\s*['"]\s*text\s*\/\s*html\s*;\s+charset\s*=\s*(?<charset>[a-z0-9-]+)\s*['"]\s*\/?\s*>/i)
			pattern_small=Regexp.new(/<\s*meta\s+charset\s*=\s*['"]?\s*(?<charset>[a-z0-9-]+)\s*['"]?\s*\/?\s*>/i)

			page_charset = page.match(pattern_big) || page.match(pattern_small)
			page_charset = page_charset[:charset] if not page_charset.nil?
			
			headers.each_pair { |k,v|
				if 'content-type'==k.downcase.strip then
					res = v.first.downcase.strip.match(/charset\s*=\s*(?<charset>[a-z0-9-]+)/i)
					headers_charset = res[:charset].upcase if not res.nil?
				end
			}
			
			page_charset = headers_charset if page_charset.nil?
			page_charset = 'ISO-8859-1' if headers_charset.nil?

			#puts "page_charset: #{page_charset}"

			page = page.encode(
				target_charset, 
				page_charset, 
				{ :replace => '_', :invalid => :replace, :undef => :replace }
			)
			
			page = page.gsub(
				pattern_big,
				"<meta http-equiv='content-type' content='text/html; charset=#{page_charset}'>"
			)
			
			page = page.gsub(
				pattern_small,
				"<meta charset='#{page_charset}' />"
			)

			return page
		end
		
		def repair_uri(uri)
			#Msg::debug("#{self.class}.#{__method__}('#{uri}')")
			
			uri = URI( uri.strip.gsub(/\/+$/,'') )
			uri.host = @current_host if uri.host.nil?
			uri.scheme = @current_scheme if uri.scheme.nil?
			
			return uri.to_s
		end
		
		def save_page(title, body)
			Msg::debug("#{self.class}.#{__method__}('#{title}')")
			
			body = body.to_html
			
			html = <<MARKUP
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
<html>

<head>
	<title>#{title}</title>
	<meta http-equiv="content-type" content="text/html;charset=utf-8" />
</head>

<body>
	#{body}
</body>

</html>
MARKUP
			
			File::write(@file_path, html) and Msg::debug " записан файл #{@file_name}"
			
			@book.link_update(
				set: {title: @title, file: @file_name}, 
				where: {id: @current_id}
			)
		end
	end
	
	def headers2ext(headers)
		#Msg::debug("#{self.class}.#{__method__}(#{headers.keys})")
		
		content_type = headers.fetch('content-type').first.strip.downcase
		
		ext = content_type.match(/^(?<type>[a-z]+)\/(?<ext>[a-z]+)$/i)[:ext].strip.downcase
	end
	
	
end


class Msg
	#~ def self.debug(msg)
		#~ puts msg
	#~ end
	
	def self.debug(msg, params={})
		#msg = msg.white.on_light_white
		params.fetch(:nobr,false) ? print(msg) : puts(msg)
		#puts "#{msg}, nobr: #{params.fetch(:nobr,false)}"
	end
	
	def self.info(msg)
		puts msg.blue
	end
	
	def self.notice(msg)
		STDERR.puts "#{msg}".cyan
	end
	
	def self.warning(*msg)
		STDERR.puts "ВНИМАНИЕ:".red
		self.prepare_msg(msg).each {|m|
			STDERR.puts m.to_s.red
		}
	end
	
	def self.error(*msg)
		STDERR.puts "ОШИБКА:".black.on_red
		self.prepare_msg(msg).each {|m|
			STDERR.puts m.to_s.black.on_red
		}
	end
	
	private
	
	def self.prepare_msg(*msg)
		msg = msg.flatten.map {|m|
			if m.kind_of? Exception then
				[m.message, m.backtrace]
			else
				m
			end
		}
		msg.flatten
	end
end


class String
	def urlencoded?
		return true if self.match(/[%0-9ABCDEF]{3,}/i)
		return false
	end
end

book = Book.new

book.title = 'Пробная книга'
book.author = 'Кумыков Андрей'
book.language = 'ru'

#book.add_source 'http://opennet.ru'
#book.add_source 'http://opennet.ru/opennews/art.shtml?num=44711'

#book.add_source 'https://ru.wikipedia.org'
#book.add_source 'https://ru.wikipedia.org/wiki/Заглавная_страница'
#book.add_source 'https://ru.wikipedia.org/wiki/Linux'
# насекомые:
#book.add_source 'https://ru.wikipedia.org/wiki/%D0%9D%D0%B0%D1%81%D0%B5%D0%BA%D0%BE%D0%BC%D1%8B%D0%B5'
# уховёртка:
book.add_source 'https://ru.wikipedia.org/wiki/%D0%A3%D1%85%D0%BE%D0%B2%D1%91%D1%80%D1%82%D0%BA%D0%B0_%D0%BE%D0%B1%D1%8B%D0%BA%D0%BD%D0%BE%D0%B2%D0%B5%D0%BD%D0%BD%D0%B0%D1%8F'
#book.add_source 'https://ru.wikipedia.org/w/index.php?title=Linux&printable=yes'


book.page_limit = 1

book.threads = 1

book.prepare
book.save

puts ''
puts book.inspect
