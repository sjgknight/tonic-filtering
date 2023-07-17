class HyperlinkGlossaryEntries < Middleman::Extension
  def initialize(app, options_hash = {}, &block)
    super
  end

  # Hook into the after_build event
  def after_build(builder)

    puts "Starting the after_build process..."

    # Retrieve all HTML files from the build
    # Looping through all files and directories in our build folder.
    #html_files = Dir.glob(File.join(builder.app.config[:build_dir], '**/*.html'))
    #html_files = Dir.glob("docs/**/*.html")

    html_files = builder.app.sitemap.resources.select { |resource| resource.ext == '.html' && !resource.path.include?('glossary') }

    #puts html_files

    # Process each HTML file
    html_files.each do |resource|
      # Retrieve the resource for the file
      #resource = builder.app.sitemap.find_resource_by_path(file)

      # Check if the resource is processable
      #next unless processable?(resource)

      # Retrieve glossary entries from resource data
      glossary_entries = app.data['glossary']

      next if glossary_entries.nil?

      # Retrieve the HTML content from the resource
      #html = resource.render
      file_path = File.join(builder.app.config[:build_dir], resource.destination_path)
      html = File.read(file_path)

      puts resource.destination_path

      # Process the HTML body to replace glossary entries with hyperlinks
      html = process_html_body(html, resource.data['title'], glossary_entries)

      # Update the resource's body with the processed HTML
      #resource.body = html
      # Update the resource's body with the processed HTML
      #resource.destination_path.sub!(/^#{builder.app.config[:build_dir]}/, '') # Update the destination path
      #resource.destination_path.sub!(/^#{builder.app.config[:build_dir]}/, '') # Update the destination path
      #builder.thor.say_status :processed, resource.destination_path
      #builder.app.files.write(resource.destination_path, html)
      destination_path = File.join(builder.app.config[:build_dir], resource.destination_path)
      File.write(destination_path, html)

    end
  end

  private

  # Check if the resource is processable
  def processable?(resource)
    resource.is_a?(Middleman::Sitemap::Resource) &&
      resource.ext == '.html' &&
      app.data['glossary'] != false
  end

  # Process the HTML body to replace glossary entries with hyperlinks
  def process_html_body(html, title, glossary_entries)
    glossary_entries.each do |glossary_entry|
      glossary_term = glossary_entry['term'].to_s.downcase
      glossary_link = '/glossary#glossary-' + glossary_term
      glossary_definition = glossary_entry['definition'].to_s.gsub('"', '&quot;')

      # Find all instances of <a> or <hx> tags and their locations in the HTML
      tags_matches = html.enum_for(:scan, /<(a|h\d)[^>]*>.*?<\/\1>/i).map { Regexp.last_match }
      tags_locations = tags_matches.map { |match| match.offset(0) }

      # Replace the glossary term instances outside <a> or <hx> tags with hyperlinks
      html.gsub!(/\b#{Regexp.escape(glossary_term)}\b/i) do |match|
        # Check if the match falls within any <a> or <hx> tags
        if tags_locations.none? { |location| location[0] <= Regexp.last_match.offset(0)[0] && location[1] >= Regexp.last_match.offset(0)[1] }
        glossary_link_with_tooltip = "<a href=\"#{glossary_link}\" class=\"group inline-block relative\">
          <span class=\"text-blue-400 hover:text-blue-600 transition-colors duration-300 focus:outline-none focus:ring focus:ring-blue-300 focus:ring-opacity-50\">#{match}</span>
          <span class=\"group-hover:opacity-100 transition-opacity bg-gray-800 px-1 text-sm text-gray-100 rounded-md absolute left-1/2 -translate-x-1/2 translate-y-2 w-auto opacity-0 m-4 mx-auto\">#{glossary_definition}</span>
        </a>"

        "#{glossary_link_with_tooltip}"
        else
          match
        end
      end
    end
    html
  end
end

# Register the extension with Middleman
::Middleman::Extensions.register(:hyperlink_glossary_entries, HyperlinkGlossaryEntries)
