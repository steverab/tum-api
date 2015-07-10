require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'iconv'

require './extensions/str.rb'

before do
  if ENV['RACK_ENV'] == 'production'
    error 426 unless request.secure?
  end
  content_type 'application/json', 'charset' => 'utf-8'
end

not_found do
  content_type 'text/plain'
  '404 - Not Found'
end

error 401 do
  content_type 'text/plain'
  '401 - Unauthorized'
end

error 403 do
  content_type 'text/plain'
  '403 - Forbidden'
end

error 426 do
  content_type 'text/plain'
  '426 - Upgrade Required'
end

get '/' do
  content_type 'text/plain'
  "Welcome to the TUM API!"
end

get '/mensa' do
  page = Nokogiri::HTML(open("http://www.studentenwerk-muenchen.de/mensa/speiseplan/speiseplan_422_-de.html"))

  resp = []

  page.xpath('//table[@class="menu"]').each do |menu|
    date = menu.css('tr')[0].css('td')[1].css('span')[0].css('a')[0].text.strip_control_characters

    currentDate = Time.now.strftime("%d.%m.%Y")
    menuDate = date.partition(' ').last

    if menuDate < currentDate
      next
    end

    dishes = []
    menu.css('tr').first.remove
    menu.css('tr').each do |dish|
      name = dish.css('td')[0].text.strip_control_characters
      description = dish.css('td')[1].css('span')[0].text.strip_control_characters
      dish.css('td')[1].css('span')[1].css('span')[0].remove
      note = dish.css('td')[1].css('span')[1].text.strip_control_characters
      dishes << {:name => name, :description => description, :note => note}
    end
    resp << {:date => date, :dishes => dishes}
  end

  resp[0..2].to_json
end
