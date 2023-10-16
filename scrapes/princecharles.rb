require 'nokogiri'
require 'json'
require 'date'
require 'watir'
require 'headless'

browser = Watir::Browser.new(:chrome, headless: true)
browser.goto('https://princecharlescinema.com/PrinceCharlesCinema.dll/Home')

all_showtimes = {}

loop do
  doc = Nokogiri::HTML(browser.html)
  date = Date.parse(doc.css("#CurrentDate").attr("data-date").value)
  films = doc.css("#FilmList .film")
  showtimes = films.map do |film|
    return nil if film.css('.soldout')
    title = film.css("h2").text
    times = film.css(".time").map(&:text).map do |t|
      {
        starts_at: DateTime.parse(date.to_s + " " + t),
        site: "Prince Charles",
        url: "https://princecharlescinema.com/PrinceCharlesCinema.dll/" + film.css("a").attr("href")
      }
    end
    { title: title, times: times }
  end.compact

  all_showtimes[date.strftime "%Y-%m-%d"] = showtimes

  browser.link(id: "NextDate").click!
  break if date >= Date.today + 7
end

File.open("./data/princecharles.json", 'w') do |file|
  file.write(JSON.pretty_generate(all_showtimes))
end
