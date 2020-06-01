require 'net/http'

def fetch(url, **stuff)
  headers = p stuff[:headers]
  content, content_type = stuff[:content]
  content_type ||= 'text/plain'

  uri = URI.parse(url)
  Net::HTTP.start(uri.hostname, uri.port, use_ssl: stuff.fetch(:use_ssl, uri.scheme == 'https')) do |http|
    verb = stuff[:verb] || content.nil? ? 'GET' : 'POST'
    http.send_request(verb, uri, content, headers)
  end
end

# api
fetch("http://localhost:20",
  headers: {"X-Bla"=> "asd"},
  content: ["hallo", "text/plain"],
  verb:"PUT",
  use_ssl: true
) if false
