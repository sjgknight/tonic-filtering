require "lib/tonic"

set :url_root, 'https://sjgknight.github.io/tonic-filtering'
set :build_dir, 'docs'

set :markdown_engine, :kramdown

# extensions
require 'lib/extensions/permalink.rb'
activate :permalink
#redirect "about.html", to: "pages/about.html"
#redirect "snippets.html", to: "pages/snippets.html"


activate :directory_indexes
activate :inline_svg
activate :external_pipeline,
         name: :webpack,
         command: build? ? "yarn run build" : "yarn run start",
         source: "dist",
         latency: 1

configure :development do
  activate :livereload
end

configure :build do
  ignore File.join(config[:js_dir], "*") # handled by External Pipeline
  activate :asset_hash
  activate :minify_css
  activate :relative_assets
end

Tonic.start(self)

#base_url is mentioned in a few places as a way to set the base url
#this would be useful e.g. where using github pages which is in a subdir
#I couldn't get it working in any of
#utils.rb, inside helpers.rb def detail_page_url(item) to pre-pend.
#@base_url = ["/tonic-filtering/"]
#set :base_url, ["/tonic-filtering/"]
#config[:base_url] = ["/tonic-filtering/"]
#set :base_url, "/hello/"
  #config[:host] = 'https://sjgknight.github.io'
  #set :http_prefix, "/tonic-filtering/"
  #set :base_url, "/tonic-filtering"
#the new config.yaml field cardurl does what I wanted
#I'm also using permalink extension from https://www.beesbot.com/middleman-permalinks-in-frontmatter/middleman-permalinks-in-frontmatter

