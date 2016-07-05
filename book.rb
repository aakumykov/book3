#!/usr/bin/env ruby
#coding: UTF-8
system 'clear'

require 'sqlite3'
require 'net/http'
require 'nokogiri'
require 'securerandom'

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
		
		@images_dir = File.join(@@work_dir,'images')
		
		if not Dir.exists?(@images_dir) then
			Dir.mkdir(@images_dir) or raise "невозможно создать каталог #{@images_dir}"
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
				#begin
					id = thr.value
					link_update(
						set: { status: 'processed' },
						where: { id: id }
					)
					@page_count += 1
				#~ rescue => e
					#~ @error_count += 1
					#~ Msg::error e.message
				#~ end
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
		Msg::debug("#{self.class}.#{__method__}(#{uri})")
		
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
		Msg::debug("#{self.class}.#{__method__}()")
		
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
	
	def uri2file_path(uri)
		#Msg::debug("#{self.class}.#{__method__}(#{uri})")
		
		file_path = File.join(@text_dir, Digest::MD5.hexdigest(uri)+'.html')
			#Msg::debug " file_path: #{file_path}"
		
		return file_path
	end
	
	
	private
		
	class Processor
		
		def initialize(book, id, uri)
			Msg::debug("#{self.class}.#{__method__}(#{id}, #{uri})")
			
			the_uri = URI(uri)
			
			@book = book
			
			@current_id = id
			@current_uri = uri
			@current_host = the_uri.host
			@current_scheme = the_uri.scheme
			@current_rule = @book.get_rule(@current_uri.to_s)
			
			@file_path = @book.uri2file_path(@current_uri)
			@file_name = File.basename(@file_path)

				#Msg::debug(" rule: #{@current_rule.class}")
		end
		
		def work
			Msg::debug("#{self.class}.#{__method__}()")
			
			@page = get_page(@current_uri)
			@title = get_title(@page)
			
			result_page = @current_rule.process_page(@page)
				
			#links_hash = collect_links(result_page)
			#result_page = make_links_offline(links_hash, result_page)
			
			save_page(@title,result_page)
			
			return @current_id
		end
		
		def get_page(uri)
			Msg::debug("#{self.class}.#{__method__}(#{uri})")
			
			data = load_page(uri: uri)
				#File.write('page1.html', data[:page])
			
			page = recode_page(data[:page], data[:headers])
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
		
		def get_title(dom)
			Msg::debug("#{self.class}.#{__method__}()")
			
			title = dom.search('//title').text
				#Msg::debug " title: #{title}"
			return title
		end
	
		def collect_links(dom)
			Msg::debug("#{self.class}.#{__method__}()")
			
			links = dom.search('//a').map { |a| a[:href] }.compact
			links = links.map { |lnk| lnk.strip }
			links = links.delete_if { |lnk| '#'==lnk[0] || lnk.empty? }
				
				Msg::debug " ссылок до уникализации #{links.count}"
			links = links.uniq
				Msg::debug " ссылок после уникализации #{links.count}"
			
			links_hash = links.map { |lnk| 
				#Msg::debug "lnk: #{lnk}"
				begin
					[lnk, repair_uri(lnk)]
				rescue => e
					Msg::warning "ОТБРОШЕНА КРИВАЯ ССЫЛКА: #{lnk}"
					nil
				end
			}.compact.to_h
			
				Msg::debug(" собрано ссылок: #{links_hash.count}")
			
			links_hash = links_hash.keep_if { |lnk_orig,lnk_full| 
				@current_rule.accept_link?(lnk_full) 
			}
			
				Msg::debug(" оставлено ссылок: #{links_hash.count}")
			
			links_hash.each_pair { |lnk_orig,lnk_full| 
				@book.link_add(@current_id, lnk_full) 
			}
			
			return links_hash
		end
		
		def make_links_offline(links_hash, page)
			Msg::debug("#{__method__}()")
			
			page.search("//a").map { |a|
				links_hash.each_pair { |lnk_orig,lnk_full|
					if a[:href]==lnk_orig then
						lnk_local = @book.uri2file_path(lnk_full) 
							#Msg::debug "локализация ссылки '#{lnk_orig}' -> '#{lnk_local}'"
						a[:href] = lnk_local
					end
				}
			}
			
			#~ links_hash.each_pair { |lnk_orig,lnk_full|
				#~ lnk_local = @book.uri2file_path(lnk_full)
				#~ page.gsub!(lnk_orig, lnk_local)
					#~ #Msg::debug " #{lnk_orig} --> #{lnk_local}"
			#~ }
			
			page
		end
		

		def get_image(uri)
			Msg::debug("#{__method__}(#{uri})")

			data = load_page(uri: uri)

			#~ return {
			#~ data: data[:page],
			#~ extension: 'jpg',
			#~ }
		end
		
		def load_page(arg)
			#Msg::debug("#{self.class}.#{__method__}(#{uri})")

			#uri = URI.escape(uri) if not uri.urlencoded?
			
			uri = URI(arg[:uri])
			redirects_limit = arg[:redirects_limit] || 10		# опасная логика...
			
			raise ArgumentError, 'слишком много перенаправлений' if redirects_limit == 0

			data = {}

			Net::HTTP.start(uri.host, uri.port, :use_ssl => 'https'==uri.scheme) { |http|

				request = Net::HTTP::Get.new(uri.request_uri)
				request['User-Agent'] = "Mozilla/5.0 (X11; Linux i686; rv:39.0) Gecko/20100101 Firefox/39.0 [TestCrawler (#{@book.contacts})]"

				response = http.request request

				case response
				when Net::HTTPRedirection then
					location = response['location']
					puts "перенаправление на '#{location}'"
					data =  send(
						__method__,
						{ :uri => location, :redirects_limit => (redirects_limit-1) }
					)
				when Net::HTTPSuccess then
					data = {
						:page => response.body,
						:headers => response.to_hash,
					}
				else
					response.value
				end
			}
			
			#puts "========== Headers: =========="
			#data[:headers].each_pair { |k,v| puts "#{k}: #{v}" }
			#puts "=========================="
		  
			return data
		end

		def recode_page(page, headers, target_charset='UTF-8')
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
		
		# возвращает хеш { src => nil }, ключи заполняются в процессе загрузки картинок; ссылки ремонтируются непосредственно
		# перед загрузкой. Хэш используется для "локализации" html-страницы.
		def load_images(params)
			Msg::debug("#{self.class}.#{__method__}()")
			
			links = params[:page].scan(/<img\s+src\s*=\s*['"](?<image_uri>[^'"]+)['"][^>]*>/).map { |lnk| lnk.first }
			
			links_hash = {}
			
			links.each { |lnk| links_hash[lnk] = nil }
			
			links_hash.each_key { |lnk|
				links_hash[lnk] = repair_uri(params[:uri], lnk)
			}
			
			links_hash.each_pair { |k,v| Msg::debug(" #{k} ---> #{v}") }
			
			#~ links_hash.each_pair { |orig_link,full_link|
				#~ begin
					#~ image_data = load_page(uri: full_link)
					#~ image_file = File.join(@images_dir,"#{rand(10000)}.jpg")
					#~ File.write(image_file,image_data)
					#~ Msg::debug("загружено изображение (#{full_link}")
				#~ rescue => e
					#~ Msg::debug("ошибка загрузки изображения (#{full_link})")
					#~ image_file = nil
				#~ end
				#~ 
				#~ links_hash[orig_link] = image_file
			#~ }
			
			links_hash
		end
		
		def fix_page_images(page, images_hash)
			Msg::debug("#{self.class}.#{__method__}()")
			
			images_hash.each_pair { |old_src, new_src|
				page = page.gsub(old_src, new_src)
			}
			
			return page
		end

		def save_page(title, body)
			Msg::debug("#{self.class}.#{__method__}(#{title})")
			
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
			
			File::write(@file_path, html) and Msg::debug "записан файл #{@file_name}"
			
			@book.link_update(
				set: {title: @title, file: @file_name}, 
				where: {id: @current_id}
			)
		end
	end
end


class Msg
	#~ def self.debug(msg)
		#~ puts msg
	#~ end
	
	def self.debug(msg, params={})
		params.fetch(:nobr,false) ? print(msg) : puts(msg)
		#puts "#{msg}, nobr: #{params.fetch(:nobr,false)}"
	end
	
	def self.info(msg)
		puts msg
	end
	
	def self.warning(msg)
		STDERR.puts "ВНИМАНИЕ: #{msg}"
	end
	
	def self.error(msg)
		STDERR.puts "ОШИБКА: #{msg}"
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
book.add_source 'https://ru.wikipedia.org/wiki/Linux'

book.page_limit = 1

book.threads = 1

book.prepare
book.save

puts ''
puts book.inspect
