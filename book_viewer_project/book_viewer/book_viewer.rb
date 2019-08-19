require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

helpers do
  def in_paragraphs(chapter)
    chapter.split(/\n\n/).map.with_index do |line, number|
      "<p id=paragraph#{number}>#{line}</p>"
    end.join
  end

  def highlight_text(text, search_term)
    text.gsub(search_term, "<strong>#{search_term}</strong>")
  end
end

# returns an array of [paragraph text, index of paragraph]
def search_paragraphs(search_term, chapter)
  paragraphs = []
  chapter.split(/\n\n/).each_with_index do |paragraph, index|
    paragraphs << [paragraph, index] if paragraph.include?(search_term)
  end
  paragraphs
end

def search_results(search_term)
  return [] if search_term.nil? || search_term.empty?
  @contents.each_with_index.with_object([]) do |(chapter_name, index), result|
    chapter_number = index + 1
    chapter = File.read("data/chp#{chapter_number}.txt")
    if chapter.include?(search_term)
      paragraphs = search_paragraphs(search_term, chapter)
      result << [chapter_name, chapter_number, paragraphs]
    end
  end
end

before do
  @contents = File.readlines('data/toc.txt')
end

get '/' do
  @title = 'The Adventures of Sherlock Holmes'

  erb :home
end

get '/search' do
  @results = search_results(params[:query])

  erb :search
end

get '/chapters/:number' do
  chapter_number = params[:number].to_i
  chapter_name = @contents[chapter_number - 1]

  redirect '/' unless (1..@contents.size).cover?(chapter_number)

  @title = "Chapter #{chapter_number}: #{chapter_name}"
  @chapter = File.read("data/chp#{chapter_number}.txt")

  erb :chapter
end
