require "lib/tonic"

#set :url_root, 'https://sjgknight.github.io/tonic-filtering'
#set :base_url, "/hello/"

#I cannot get a base url variable in utils.rb or inside
#helpers.rb def detail_page_url(item) to pre-pend.
#so it's currently hardcoded
#@base_url = ["/tonic-filtering/"]
#set :base_url, ["/tonic-filtering/"]
#config[:base_url] = ["/tonic-filtering/"]

activate :directory_indexes
activate :inline_svg
activate :external_pipeline,
         name: :webpack,
         command: build? ? "yarn run build" : "yarn run start",
         source: "dist",
         latency: 1

redirect "about.html", to: "pages/about.html"

configure :development do
  #set :base_url, "/hello/"
  activate :livereload
end

configure :build do
  #config[:host] = 'https://sjgknight.github.io'
  #set :http_prefix, "/tonic-filtering/"
  #set :base_url, "/tonic-filtering"
  set :build_dir, 'docs'
  ignore File.join(config[:js_dir], "*") # handled by External Pipeline
  activate :asset_hash
  activate :minify_css
  #set :relative_links, true
  activate :relative_assets
end


Tonic.start(self)
