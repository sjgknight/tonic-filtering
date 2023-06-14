# lib/extensions/permalink.rb
class Permalink < Middleman::Extension
    def manipulate_resource_list(resources)
        resources.each do |resource|
            if resource.respond_to?(:data) and resource.data[:permalink]
                resource.destination_path = resource.data[:permalink] + '/index.html'
            end
        end
    end
end

::Middleman::Extensions.register(:permalink, Permalink)
