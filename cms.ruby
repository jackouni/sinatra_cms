require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require "rack"
require "json"

get '/' do
  "Getting Started"
end

