require 'yaml'
require 'virtus'
require 'eson'

EXCLUDE = ['.', '..', '.git', '.gitignore', 'script', 'README.md']
INDEX = 'transcripts'

def read_file(file)
  content = File.read(file, :encoding => 'utf-8')
  if content.include?('---')
    content.split('---').reject(&:empty?)
  else
    ['', content]
  end
end

def convert_frontmatter(frontmatter_str)
  YAML.load(frontmatter_str)
end

class Talk
  include Virtus.model

  attribute :speaker, String, default: ''
  attribute :title, String, default: ''
  attribute :teaser, String, default: ''
  attribute :text, String, default: ''
end

def push_to_es(talks)
  c = Eson::HTTP::Client.new(:server => 'http://localhost:9200')
  talks.each_with_index do |talk, index|
    c.index :index => INDEX,
      :type => 'transcript',
      :id => index,
      :doc => talk.attributes
  end
end

def import(folder)
  talks = []
  Dir.foreach(folder) do |file|
    if EXCLUDE.include?(file)
      next
    end
    frontmatter_str, md = read_file(File.join(folder, file))
    frontmatter = convert_frontmatter(frontmatter_str)
    puts "FILE: #{file}"
    puts "FRONTMATTER: #{frontmatter}"
    talks << Talk.new(frontmatter.merge('text' => md))
  end
  push_to_es(talks)
end

import(ARGV.pop)
