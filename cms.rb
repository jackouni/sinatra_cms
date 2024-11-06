require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require "rack"
require "json"
require "redcarpet"


configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(64)
end

before do 
  @root  = File.expand_path("..", __FILE__)
  @files = Dir.children('data')
end

helpers do
  def remove_ext(file_name)
    File.basename(file_name, ".*")
  end 

  def render_markdown(content)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(content)
  end

  def load_file_contents(path)
    content = File.read(path)

    case File.extname(path)
    when ".txt" then headers["Content-Type"] = "text/plain"
    when ".md"  then content = render_markdown(content)
    end

    content
  end
end

get '/' do
  erb :index, layout: :layout
end

get '/:file_name' do
  @file_name = params[:file_name]

  if @files.include? @file_name
    load_file_contents("data/#{@file_name}")
  else
    session[:error] = "#{@file_name} does not exist."
    redirect '/'
  end
end