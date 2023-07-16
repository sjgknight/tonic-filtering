# Adapted (with chatgpt) from https://github.com/MarcSchmidt/jekyll-hyperlinkify-glossary/blob/main/lib/jekyll-hyperlinkify-glossary.rb
# MarcSchmidt's code under an MIT license
# Enrich all documents and pages with an array of all glossary entries and their synonyms

class EnrichGlossaryEntries < Middleman::Extension
  def initialize(app, options_hash = {}, &block)
    super
  end

  def after_configuration
    # Retrieve the base URL from the app configuration or set it to an empty string
    base_url = app.config['hyperlinkify_glossary_base_url'] || ""

    # Initialize an empty array for glossary entries
    glossary_entries = []

    # Iterate over the glossary data and create entries with URL, term, and synonyms
    app.data.glossary.each do |entry|
      url = base_url.to_s + entry['url'].to_s
      synonyms = entry['synonyms'] || []
      glossary_entries << [url, entry['term'], *synonyms].map(&:downcase)
    end

    # Add glossary_entries metadata to all resources in the sitemap
    app.sitemap.resources.each do |resource|
      resource.add_metadata('glossary_entries' => glossary_entries)
    end
  end
end

# Register the extension with Middleman
::Middleman::Extensions.register(:enrich_glossary_entries, EnrichGlossaryEntries)
