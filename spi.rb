require 'rest_client'
require 'nokogiri'
require 'json'
require 'iconv'
require 'uri'
require 'capybara'
require 'selenium-webdriver'
require_relative 'course.rb'
require_relative 'spec_helper.rb'
# 難得寫註解，總該碎碎念。
class Spider
  attr_reader :semester_list, :courses_list, :query_url, :result_url
  include Capybara::DSL
  def initialize
  	@query_url = "http://www.apexbook.tw/index.php?php_mode=viewbook&rk=dd13044fb6aa6c06cf221ca404e2e315"
    Capybara.default_driver = :selenium
    @front_url = "http://www.apexbook.tw/"
  end

  def prepare_post_data
    puts "hey yo bestwise here"
    nil
  end

  def get_books
  	# 初始 courses 陣列
    @books = []
    puts "getting books...\n"
    # 一一點進去YO
    100.times do |n|
      filename = "./bigshit/#{n+1}.html"
      f = File.open(filename)
      puts n+1
      contents = ""
      f.each { |line| contents << line }
      # puts contents

      ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
      ra = Nokogiri::HTML(contents.to_s)
      @book_now_is = 0
      @book_before = ""
      @book_now = ""
      ra.css('td td tr:nth-of-type(n+3) a.CDB').each_with_index do |yo, hey|
        # puts hey#, yo['href']
        link = yo['href'].split('/').last
        puts link
        # puts "price"
        # puts ra.css('td td td td td tr:nth-of-type(n+3) td:nth-of-type(5)')[hey].text
        # 幹我拿到連結了 爽
        r = RestClient.get @front_url + link
        ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
        page = Nokogiri::HTML(ic.iconv(r.to_s))

        book_name = page.css('span.book_name').text
        @book_now = book_name
        if @book_before == @book_now
          puts "幹 一樣"
        else
          @book_now_is += 1
        end
        @book_before = @book_now
        author = ""
        isbn_10 = ""
        isbn_13 = ""
        publisher = ""
        publish_date = ""
        kind = ""
        puts "hey is #{hey}"
        price = ra.css('td td td td td tr:nth-of-type(n+3) td:nth-of-type(5)')[@book_now_is-1].text
        info_in_amazon = @front_url + page.css('form a')[1]['href'].to_s
        url = @front_url + link
        # puts "ama",info_in_amazon

        pack = page.css('.mainContent tr').first.to_s
        out_pack = pack.split("<br>")
        # puts "outback"
        # puts out_pack
        out_pack.each do |hi|
          # puts "hi: #{hi}"
          # puts "split: #{hi.split("：")}"
          # puts "split first: #{hi.split("：").first}"
          if hi.split("：").first == "\n作者"
            author = hi.split("：").last
          elsif hi.split("：").first == "\nISBN-10"
            isbn_10 = hi.split("：").last
          elsif hi.split("：").first == "\nISBN-13"
            isbn_13 = hi.split("：").last
          elsif hi.split("：").first == "\n出版商"
            publisher = hi.split("：").last
          elsif hi.split("：").first == "\n裝訂別"
            kind = hi.split("：").last
          elsif hi.split("：").first == "\n出版日期"
            publish_date = hi.split("：").last
          end     
        end

        # a = gets.chomp
        @books << Course.new({
          :book_name => book_name,
          :author => author,
          :isbn_10 => isbn_10,
          :isbn_13 => isbn_13,
          :publisher => publisher,
          :publish_date => publish_date,
          :kind => kind,
          :price => price,
          :info_in_amazon => info_in_amazon,
          :url => url
          }).to_hash

        puts "book_name: #{book_name}" ,"author: #{author}" ,"isbn_10: #{isbn_10}" ,"isbn_13: #{isbn_13}" ,"publisher: #{publisher}" ,"publish_date: #{publish_date}" ,"kind: #{kind}" ,"price: #{price}" ,"info_in_amazon: #{info_in_amazon}" ,"url: #{url}"

        # puts out_pack
      end

      # puts r

      f.close
    end
  end
  

  def save_to(filename='liwen_books.json') #now on page 2 part 3
    File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(@books))}
  end
    
end






spider = Spider.new
spider.prepare_post_data
spider.get_books
spider.save_to