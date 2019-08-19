require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'
require 'sinatra/content_for'
require 'yaml'
require 'bcrypt'
require 'pry' if development?
require 'fileutils'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  @supported_file_extensions = ['.txt', '.md']
  @supported_image_extensions = ['.jpg', '.png', '.pdf']

  text_path = File.join(data_path, '*')
  @text_files = Dir.glob(text_path).map { |file| File.basename(file) }

  img_path = File.join(public_path, 'images', '*')
  @images = Dir.glob(img_path).map { |file| File.basename(file) }

  @all_files = @text_files + @images
  @users = load_users
  @history = load_history
end

#### HELPERS ####

## path helpers ##

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def public_path
  File.expand_path('../public', __FILE__)
end

def history_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/history.yml', __FILE__)
  else
    File.expand_path('../history/history.yml', __FILE__)
  end
end

def users_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/users.yml', __FILE__)
  else
    File.expand_path('../users/users.yml', __FILE__)
  end
end

def get_file_path(file_name)
  extname = File.extname(file_name)
  if @supported_file_extensions.include?(extname)
    File.join(data_path, file_name)
  else
    File.join(public_path, 'images', file_name)
  end
end

## validation helpers ##

def empty_input?(input)
  input.strip.empty?
end

def validate_name(name)
  if empty_input?(name)
    'A name is required'
  elsif !@supported_file_extensions.include?(File.extname(name))
    supported = @supported_file_extensions.join(', ')
    "That extension is not supported. Supported extensions: #{supported}"
  end
end

def validate_user(username, password)
  if @users.include?(username)
    password = @users[username]
    bcrypt_password = BCrypt::Password.new(password)
    password == bcrypt_password
  else
    false
  end
end

def taken_username?(username)
  @users.include?(username)
end

def signed_in?
  session.key?(:current_user)
end

def require_signed_in_user
  return if signed_in?
  session[:failure] = 'You must be signed in to do that'
  redirect '/'
end

## YAML helpers ##

def load_history
  Psych.load_file(history_path, {})
end

def write_history
  File.write(history_path, @history.to_yaml)
end

def load_users
  Psych.load_file(users_path, {})
end

def write_users
  File.write(users_path, @users.to_yaml)
end

## view helpers ##

def render_markdown(text)
  object = Redcarpet::Render::HTML
  markdown = Redcarpet::Markdown.new(object, fenced_code_blocks: true)
  markdown.render(text)
end

## file helpers ##

def copied_file_name(source_file_name)
  base, extension = source_file_name.split('.')
  base << '_copy.'
  base << extension
end

def load_txt_file(content)
  headers['Content-Type'] = 'text/plain'
  content
end

def load_md_file(content)
  erb render_markdown(content)
end

def load_image_file
  erb :image
end

def load_file(file_path)
  content = File.read(file_path)
  @filename = File.basename(file_path)

  case File.extname(file_path)
  when '.txt'
    load_txt_file(content)
  when '.md'
    load_md_file(content)
  else
    erb :image
  end
end

#### ROUTES #####

get '/' do
  erb :index
end

## create or upload a file ##

get '/new' do
  require_signed_in_user
  erb :new
end

post '/new' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)

  if validate_name(file_name)
    session[:failure] = validate_name(file_name)
    status 422

    erb :new
  else
    File.write(file_path, '')
    session[:success] = "#{file_name} was created"

    redirect '/'
  end
end

post '/upload' do
  file_name = params[:file][:filename]
  tempfile = params[:file][:tempfile]
  path = get_file_path(file_name)

  File.open(path, 'w') do |f|
    f.write(tempfile.read)
  end

  session[:success] = "#{file_name} uploaded successfully"
  redirect '/'
end

## render a file ##

get '/:file_name' do
  file_name = params[:file_name]
  file_path = get_file_path(file_name)

  if @all_files.include?(file_name)
    load_file(file_path)
  else
    session[:failure] = "#{file_name} does not exist"
    redirect '/'
  end
end

## update a file ##

get '/:file_name/edit' do
  require_signed_in_user

  @file_name = params[:file_name]
  @file_path = get_file_path(@file_name)
  @content = File.read(@file_path)

  erb :edit
end

post '/:file_name/edit' do
  new_text = params[:content]
  file_name = params[:file_name]
  file_path = get_file_path(file_name)

  File.write(file_path, new_text)

  (@history[file_name] ||= []) << new_text
  write_history

  session[:success] = "#{file_name} has been updated"
  redirect '/'
end

## duplicate or delete a file ##

post '/:file_name/delete' do
  require_signed_in_user

  file_name = params[:file_name]
  file_path = get_file_path(file_name)

  File.delete(file_path)
  session[:success] = "#{file_name} was deleted"

  redirect '/'
end

post '/:file_name/duplicate' do
  require_signed_in_user

  source_file_name = params[:file_name]
  source_file_path = get_file_path(source_file_name)

  copied_file_name = copied_file_name(source_file_name)
  copied_file_path = get_file_path(copied_file_name)

  FileUtils.cp(source_file_path, copied_file_path)
  session[:success] = "#{source_file_name} was duplicated"

  redirect '/'
end

## user sign-in/ sign-out/ sign-up ##

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  username = params[:username]
  password = params[:password]
  validated = validate_user(username, password)

  if validated
    session[:current_user] = username
    session[:success] = 'Welcome!'

    redirect '/'
  else
    session[:failure] = 'Invalid credentials'
    status 422

    erb :signin
  end
end

post '/users/signout' do
  session.delete(:current_user)
  session[:success] = 'You have been signed out'

  redirect '/'
end

post '/users/signup' do
  username = params[:signup_username]
  password = params[:password]
  taken = taken_username?(username)
  empty = empty_input?(username)

  if empty
    session[:failure] = 'Invalid username'
    status 422

    erb :signin
  elsif taken
    session[:failure] = 'Sorry, that username is taken'
    status 422

    erb :signin
  else
    bcrypt_password = BCrypt::Password.create(password)
    @users[username] = bcrypt_password.to_s
    write_users
    session[:current_user] = username
    session[:success] = "Welcome to CMS, #{username}!"

    redirect '/'
  end
end

## view file history ##

get '/:file_name/history' do
  require_signed_in_user

  @file_name = params[:file_name]
  @file_path = get_file_path(@file_name)
  @file_history = @history[@file_name]

  erb :history
end
