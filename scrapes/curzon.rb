require 'httparty'
require 'json'
require 'date'

require_relative './curzon/auth.rb'

module Curzon

  class Showtimes
    attr_reader :token, :cinemas, :date
    def initialize(token, cinemas, date = Time.now)
      @token = token
      @cinemas = cinemas
      @date = date
    end

    def fetch!
      showtimes.group_by { |showtime| showtime[:film]['id'] }.map do |(_, listings)|
        film = listings.first[:film]
        {
          title: film['title']['text'],
          trailer: film['trailerUrl'],
          synopsis: film['synopsis']['text'],
          runtime: film['runtimeInMinutes'],
          times: listings.map do |listing|
            {
              starts_at: listing[:starts_at],
              site: listing[:site],
              url: listing[:url]
            }
          end
        }
      end
    end

    def showtimes
      @showtimes ||= data['showtimes'].reject {|showtime| showtime['isSoldOut']}.filter_map do |showtime|
        site = "Curzon " + sites[showtime['siteId']]
        film = films[showtime['filmId']]
        {
          film: film,
          starts_at: showtime['schedule']['startsAt'],
          site: site,
          url: "https://www.curzon.com/ticketing/seats/#{showtime["id"]}/"
        }
      end
    end

    def sites
      @sites ||= data['relatedData']['sites'].reduce({}) { |acc, site| acc[site['id']] = site['name']['text']; acc }
    end

    def films
      @films ||= data['relatedData']['films'].reduce({}) {|acc, film| acc[film['id']] = film; acc }
    end

    def data
      @data ||= HTTParty.get(
        "https://vwc.curzon.com/WSVistaWebClient/ocapi/v1/showtimes/by-business-date/#{date.strftime "%Y-%m-%d"}",
        format: :json,
        query: {
          'siteIds' => cinemas,
        },
        headers: { 'accept' => 'application/json', authorization: "Bearer #{token}"}
      )
    end
  end
end

token = Curzon::Auth.token!
cinemas = ['ALD1', 'SOH1', 'VIC1', 'MAY1', 'HOX1', 'CAM1', 'BLO1']
showtimes = {}

Date.today.upto(Date.today + 7) do |date|
  showtimes[date.strftime('%Y-%m-%d')] = Curzon::Showtimes.new(token, cinemas, date).fetch!
end

File.open("./data/curzon.json", 'w') do |file|
  file.write(JSON.pretty_generate(showtimes))
end
