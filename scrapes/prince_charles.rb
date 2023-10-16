require 'nokogiri'
require 'httparty'
require 'json'
require 'date'

doc = Nokogiri::HTML(HTTParty.get('https://princecharlescinema.com/PrinceCharlesCinema.dll/Home'))


loop do
  showtimes = []
  date = Date.parse(doc.css("#CurrentDate").attr("data-date").value)
  films = doc.css("#FilmList .film")
  films.each do |film|
    title = film.css("h2").text
    url = "https://princecharlescinema.com/PrinceCharlesCinema.dll/" + film.css("a").attr("href")
    times = film.css(".time").map(&:text).map do |t|
      {
        starts_at: DateTime.parse(date.to_s + " " + t),
        site: "Prince Charles"
      }
    end
  end
  break if date >= Date.today + 7
end
