require 'base64'
require 'digest'

module Percy
  class Client

    # A simple data container object used to pass data to create_snapshot.
    class Resource
      attr_accessor :sha
      attr_accessor :resource_url
      attr_accessor :is_root
      attr_accessor :mimetype
      attr_accessor :content

      def initialize(sha, resource_url, options = {})
        @sha = sha
        @resource_url = resource_url
        @is_root = options[:is_root]
        @mimetype = options[:mimetype]

        # For user convenience of temporarily storing content with other data, but the actual data
        # is never included when serialized.
        @content = options[:content]
      end

      def serialize
        {
          'type' => 'resources',
          'id' => sha,
          'resource-url' => resource_url,
          'mimetype' => mimetype,
          'is-root' => is_root,
        }
      end

      def inspect
        content_msg = content.nil? ? '' : "content.length: #{content.length}"
        "<Resource #{sha} #{resource_url} is_root:#{!!is_root} #{mimetype} #{content_msg}>"
      end
      alias_method :to_s, :inspect
    end

    module Resources
      def upload_resource(build_id, content)
        sha = Digest::SHA256.hexdigest(content)
        data = {
          'data' => {
            'type' => 'resources',
            'attributes' => {
              'id' => sha,
              'base64-content' => Base64.strict_encode64(content),
            },
          },
        }
        begin
          post("#{config.api_url}/builds/#{build_id}/resources/", data)
        rescue Percy::Client::ClientError => e
          raise e if e.env.status != 409
          STDERR.puts "[percy] Warning: unnecessary resource reuploaded with SHA-256: #{sha}"
        end
        true
      end
    end
  end
end
