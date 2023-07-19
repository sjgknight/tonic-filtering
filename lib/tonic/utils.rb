module Tonic
  module Utils
    extend self

    def slugify(text)
      text&.parameterize
    end

    def strip_truncate(html, length)
      truncate(strip_tags(html), length: length)
    end

    def single_word?(string)
      !string.strip.include? " "
    end

    def render_tags(tags)
      return if !tags

      tags.sort.uniq.map do |tag|
        "<span class='tag'>#{tag}</span>"
      end.join(" ")
    end

    def render_tag_links(tags)
      return if !tags
        tags.compact.uniq.sort.map do |tag|
        "<a href='#{config.cardurl}?tags=#{tag}' class='tag'>#{tag}</a>".html_safe
      end.join(" ")
    end

    def render_principle_links(principles)
      return if !principles
        "<b>Principles:</b>" + principles.compact.uniq.sort.map do |principle|
        "<a href='#{config.cardurl}?global=#{principle}' class='tag'>#{data.collection.select { |item| item.name == principle }.map(&:title).join}</a>".html_safe
      end.join(" ")
    end

 def render_links(fields)
  fields.map do |field|
    next unless current_page.data[field]

    values = data.collection.flat_map(&field).compact.sort.uniq
    next if values.empty?

    link_html = values.map do |value|
      matching_items = data.collection.select { |item| item.send(field)&.include?(value) }
      titles = matching_items.map(&:title).join(", ")
      #tried to prepend base_url before global here
      link_url = "#{config.cardurl}?global=#{value}"
      #link_url = "#{value}"
      link_to(titles, link_url, { :class => 'tag'})
    end.join(" ")

    "<b>#{field.capitalize}:</b> #{link_html}".html_safe
  end.compact.join(" ").html_safe
end

def render_link_values(value)
  value.map do |v|
      matching_items = data.collection.select { |item| item.name == v }
      titles = matching_items.map(&:title).join(", ")
      link_url = "/#{v}"
      link_url = link_url.downcase
      #link_url = "#{config.cardurl}?global=#{v}"
      link_to(titles, link_url, { :class => 'tag'})
  end.join(" ").html_safe
end

    def render_hash(hash)
      hash.map do |k, v|
        if is_hash?(v)
          render_hash(v)
        else
          "#{k.titleize}: #{v}"
        end
      end.join(" | ")
    end

    def render_video(video_url)
      embed_url = VideoInfo.new(video_url).embed_url

      "<iframe class='w-full aspect-video' src='#{embed_url}' allowfullscreen></iframe>"
    end

    def render_audio(audio_url)
      "<audio controls src='#{audio_url}'></audio>"
    end

    def is_bool?(value)
      value.is_a?(TrueClass) || value.is_a?(FalseClass)
    end

    def is_date?(value)
      Date.parse(value)
    rescue Date::Error
      false
    end

    def is_url?(string)
      string.match?(URI.regexp)
    end

    def is_email?(string)
      string.match?(URI::MailTo::EMAIL_REGEXP)
    end

    def is_hash?(object)
      object.class.name.end_with?("Hash")
    end

    def is_video?(string)
      VideoInfo.valid_url?(string)
    end

    def is_audio?(string)
      string.match?(/\.(mp3|ogg|wav)$/)
    end
  end
end
