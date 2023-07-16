class GlossaryLinkGenerator < ::Middleman::Extension
  def after_build(builder)
    # Retrieve glossary data from app data
    glossary_terms = app.data.glossary

    # Process each page on the site
    app.sitemap.resources.each do |resource|
      next unless resource.binary? || resource.ext == ".html"

      # Replace glossary terms with links in the page content
      glossary_terms.each do |entry|
        term = entry['term']
        resource.add_metadata(options: { glossary_terms: glossary_terms })

        # regular expression to exclude matches within specific HTML elements
        #regex = /(?<!<\/?(?:a|h\d|code|pre|img)[^>]*>)#{Regexp.escape(term)}/i
        #regex = /(?<!<\/(?:a|h\d|code|pre|img)[^>]*>)#{Regexp.escape(term)}/i
        #regex = /(?<!<\/(?:a|h\d|code|pre|img))#{Regexp.escape(term)}/i
        #regex = /(?<!<\/(?:a|h\d|code|pre|img))\b#{Regexp.escape(term)}\b/i
        #regex = /(?<!<\/(?:a|h\d|code|pre|img))#{Regexp.escape(term)}/i
        regex = /#{Regexp.escape(term)}/i
        #content = resource.source_file.read
#        content = app.render(resource)
        content = File.read(resource.source_file).force_encoding("UTF-8")
        # resource.buffer.string.gsub!(/term/i) do |match|
        #updated_content = content.gsub_file(regex) do |match|
        updated_content = content.gsub(regex) do |match|
          "<a href='/glossary.html##{term.downcase}'>#{term}</a>".force_encoding("UTF-8")

        end

        # Write the updated content back to the file
        File.write(resource.source_file, updated_content)
      end
    end
  end
end

::Middleman::Extensions.register(:glossary_link_generator, GlossaryLinkGenerator)
