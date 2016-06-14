#!/usr/bin/env ruby
#coding: UTF-8


class Book
	attr_reader :title, :author, :language

	def initialize
		@title = 'Новая книга'
		@author = 'Неизвестный автор'
		@language = 'ru'

		@source = []
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

	def add_source(src)
		@source << src.to_s
	end

	def prepare
		puts "#{self.class}.#{__method__}()"
	end

	def save
		puts "#{self.class}.#{__method__}()"
	end
end


book = Book.new

book.title = 'Пробная книга'
book.author = 'Кумыков Андрей'
book.language = 'ru'

book.add_source 'http://opennet.ru'
book.add_source 'http://geektimes.ru'

book.prepare

book.save

puts book.inspect

