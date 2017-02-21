require 'open-uri'
require 'nokogiri'
require 'json'

class Article
	def initialize(id, title, raiting, description, date, comments)
		@id, @title, @raiting, @description, @date, @comments = id, title, raiting, description, date, comments
	end
	def id
		@id
	end
	def title
		@title
	end
	def raiting
		@raiting
	end
	def description
		@description
	end
	def date
		@date
	end
	def comments
		@comments
	end
end

def readPage(url)
  html = open(url)
  doc = Nokogiri::HTML(html)
  doc.css('.responses__item').each do |item|
    article_id = item['data-id'].to_i
    article_url = "http://www.banki.ru/services/responses/bank/response/#{article_id}/"
    title = item.at_css('.margin-left-xx-small').text.strip
    raiting = item.at_css('.responses__item__rating').text.gsub("\n", '').strip
    description = item.at_css('.markup-inside-small--bullet').text.strip
    date = item.at_css('.display-inline-block').text.strip
    comments = get_comments(article_url)
    $articles.push( Article.new(article_id, title, raiting, description, date, comments) )
  end
end

def get_comments(article_url)
  result = []
  html = open(article_url)
  doc = Nokogiri::HTML(html)
  doc.css('.response-thread-item').each do |c|
    if c.to_s.include? '{'
      tmp = JSON.parse(c["data-answer"])
      datetime = tmp["datetime"].strip
      author = tmp["author"]["name"].strip
      text = c.css("script[data-name='answer-text']").text.strip
      if text != ""
        comment = "AUTHOR: #{author} DATETIME: #{datetime} TEXT: #{text}"
        result.push(comment)
      end
    end
  end
  return result
end


$articles = []

(ARGV[0]..ARGV[1]).each do |i|
 STDOUT.write "\r#{i} from #{ARGV[1]}"
 url = 'http://www.banki.ru/services/responses/bank/sberbank/?page=' + i.to_s
 readPage(url)
end

builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
  xml.root {
    xml.articles {
      $articles.each { |a|
        xml.article {
          xml.id a.id
          xml.title a.title
          xml.raiting a.raiting
          xml.description a.description
          xml.date a.date
          xml.comments {
            a.comments.each { |c|
              xml.comment_ c
            }
          }
        }
      }
    }
  }
end

File.open('out.xml', 'w') { |file| file.write(builder.to_xml) }
puts