# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'
require 'pry'

require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    FileUtils.mkdir_p(data_path)
    FileUtils.touch('test.jpg')
    reset_users_yaml
  end

  def teardown
    FileUtils.rm_rf(data_path)
    FileUtils.rm('test.jpg')
  end

  def create_document(name, content = '')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def reset_users_yaml
    @users = load_users
    @users.reject! { |user| user != 'admin' }
    write_users
  end

  def session
    last_request.env['rack.session']
  end

  def admin_session
    { 'rack.session' => { current_user: 'admin' } }
  end

  def app
    Sinatra::Application
  end

  def test_index
    create_document('changes.txt')
    create_document('about.txt')
    create_document('history.txt')

    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'changes.txt'
    assert_includes last_response.body, 'history.txt'
    assert_includes last_response.body, 'about.txt'
  end

  def test_view_text_file
    create_document('history.txt', '1993 - Yukihiro Matsumoto dreams up Ruby.')

    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    line = '1993 - Yukihiro Matsumoto dreams up Ruby.'
    assert_includes last_response.body, line
  end

  def test_file_doesnt_exist
    get '/not_a_file'

    assert_equal 302, last_response.status
    assert_equal 'not_a_file does not exist', session[:failure]
  end

  def test_view_markdown_file
    create_document('markdown.md', '## ***Classes and Objects***')

    get '/markdown.md'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '<em>Classes and Objects</em>'
  end

  def test_edit_file
    create_document('changes.txt')

    get '/changes.txt/edit', {}, admin_session

    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '<textarea'

    post '/changes.txt/edit', content: 'This is new content.'

    assert_equal 302, last_response.status
    assert_equal 'changes.txt has been updated', session[:success]

    get '/changes.txt'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'This is new content.'
  end

  def test_edit_without_admin_priviledges
    create_document('changes.txt')

    get '/changes.txt/edit'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that', session[:failure]

    get last_response['Location']

    assert_includes last_response.body, 'Sign in'
  end

  def test_create_file
    get '/new', {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Create a new document'

    post '/new', file_name: 'test.txt'

    assert_equal 302, last_response.status
    assert_equal 'test.txt was created', session[:success]

    get '/'
    assert_includes last_response.body, 'test.txt'
  end

  def test_create_file_without_admin_priviledges
    get '/new'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that', session[:failure]

    get last_response['Location']

    assert_includes last_response.body, 'Sign in'
  end

  def test_create_file_with_invalid_input
    post '/new', file_name: '     '

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A name is required'
  end

  def test_create_file_with_unsupported_extension
    post '/new', file_name: 'test.pdf'

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'That extension is not supported.'
  end

  def test_delete_file
    create_document('delete_me.txt')

    post '/delete_me.txt/delete', {}, admin_session

    assert_equal 302, last_response.status
    assert_equal 'delete_me.txt was deleted', session[:success]

    get '/'

    refute_includes last_response.body, 'href="delete_me.txt"'
  end

  def test_delete_without_admin_priviledges
    post '/delete_me.txt/delete'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that', session[:failure]

    get last_response['Location']

    assert_includes last_response.body, 'Sign in'
  end

  def test_sign_in_form
    get '/users/signin'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Username'
  end

  def test_sign_in
    post '/users/signin', username: 'admin', password: 'secret'

    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:success]
    assert_equal 'admin', session[:current_user]

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Signed in as <em>admin</em>'
    assert_includes last_response.body, 'Sign Out</button>'
  end

  def test_sign_up
    post '/users/signup', signup_username: 'ben', password: 'harvey'

    assert_equal 302, last_response.status
    assert_equal 'Welcome to CMS, ben!', session[:success]
    assert_equal 'ben', session[:current_user]

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Signed in as <em>ben</em>'
  end

  def test_sign_out
    get '/', {}, 'rack.session' => { current_user: 'admin' }
    assert_includes last_response.body, 'Signed in as <em>admin</em>'

    post 'users/signout'

    assert_equal 302, last_response.status
    assert_equal 'You have been signed out', session[:success]

    get last_response['Location']

    assert_nil session[:current_use]
    assert_includes last_response.body, 'Sign in'
  end

  def test_sign_in_with_invalid_credentials
    post '/users/signin', username: 'bad', password: 'worse'

    assert_equal last_response.status, 422

    assert_nil session[:current_user]
    assert_includes last_response.body, 'Invalid credentials'
    assert_includes last_response.body, 'value="bad"'
  end

  def test_sign_up_with_empty_username
    post '/users/signup', signup_username: '', password: 'worse'

    assert_equal last_response.status, 422

    assert_nil session[:current_user]
    assert_includes last_response.body, 'Invalid username'
  end

  def test_sign_up_duplicate_username
    post '/users/signup', signup_username: 'admin', password: 'worse'

    assert_equal last_response.status, 422

    assert_nil session[:current_user]
    assert_includes last_response.body, 'Sorry, that username is taken'
  end

  def test_upload_image
    get '/new', {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Upload an image'

    upload = Rack::Test::UploadedFile.new('test.jpg', 'image/jpeg')
    post '/upload', 'file' => upload

    assert_equal 302, last_response.status
    assert_equal 'test.jpg uploaded successfully', session[:success]

    get last_response['Location']

    assert_includes last_response.body, 'test.jpg'

    # teardown
    test_image_path = File.join(public_path, 'images', 'test.jpg')
    FileUtils.rm(test_image_path)
  end

  def test_add_history
    create_document('test.txt')

    get '/test.txt/edit', {}, admin_session

    post '/test.txt/edit', content: 'This is new content.'

    assert_equal 302, last_response.status
    assert_equal 'test.txt has been updated', session[:success]

    get last_response['Location']
    assert_includes last_response.body, '<a href="/test.txt/history">'
  end

  def test_view_history
    create_document('test.txt')

    get '/test.txt/edit', {}, admin_session

    post '/test.txt/edit', content: 'This is new content.'

    post '/test.txt/edit', content: 'This is new content. More new content.'

    get '/test.txt/history'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<li>This is new content.</li>'
    line = '<li>This is new content. More new content.</li>'
    assert_includes last_response.body, line
    assert_includes last_response.body, 'Revert to this version</button>'
  end
end
