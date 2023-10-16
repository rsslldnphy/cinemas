require 'json'
require 'httparty'
require 'date'

curzon = JSON.parse(File.read("./data/curzon.json"))
princecharles = JSON.parse(File.read("./data/princecharles.json"))

films = (princecharles.values + curzon.values).flatten.map { |f| f['title'] }.sort.uniq
metadata = films.reduce({}) do |acc, film|
  result = HTTParty.get(
    "https://api.themoviedb.org/3/search/movie",
    format: :json,
    query: {
      api_key: "15d2ea6d0dc1d476efbca3eba2b9bbfb",
      query: film.gsub(/DocHouse: /, "")
    }
  )['results'][0]
  acc[film] = {
    backdrop: result['backdrop_path'] ? "https://image.tmdb.org/t/p/w500/#{result['backdrop_path']}" : nil,
    poster:  result['poster_path'] ? "https://image.tmdb.org/t/p/w500/#{result['poster_path']}" : nil,
    overview: result['overview'],
    release_date: result['release_date'],
  } if result
  sleep 0.05
  acc
end

File.open("./data/metadata.json", 'w') do |file|
  file.write(JSON.pretty_generate(metadata))
end
