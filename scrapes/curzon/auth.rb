module Curzon
  class Auth
    def self.token!
      HTTParty.get('https://www.curzon.com').body.lines.find do |line|
        line.match? /occInititialiseData/
      end.gsub /^.*"authToken":"([^"]*)".*$/, '\1'
    end
  end
end
