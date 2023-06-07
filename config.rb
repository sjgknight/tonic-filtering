require "lib/tonic"

set :build_dir, 'docs'
set :url_root, 'https://sjgknight.github.io/tonic-filtering'

activate :directory_indexes
activate :inline_svg
activate :external_pipeline,
         name: :webpack,
         command: build? ? "yarn run build" : "yarn run start",
         source: "dist",
         latency: 1

configure :development do
  set :base_url, "/"
  activate :livereload
end

configure :build do
  #config[:host] = 'https://sjgknight.github.io'
  #set :http_prefix, "/tonic-filtering/"
  set :base_url, "/tonic-filtering"
  ignore File.join(config[:js_dir], "*") # handled by External Pipeline
  activate :asset_hash
  activate :minify_css
  activate :relative_assets
end



Tonic.start(self)
