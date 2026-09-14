require "socket"
require "uri"

PORT = Integer(ENV.fetch("PORT", "10000"))
ROOT = File.expand_path(__dir__)
TYPES = {
  ".html" => "text/html; charset=utf-8",
  ".css" => "text/css; charset=utf-8",
  ".js" => "application/javascript; charset=utf-8",
  ".xml" => "application/xml; charset=utf-8",
  ".txt" => "text/plain; charset=utf-8",
  ".json" => "application/json; charset=utf-8"
}

server = TCPServer.new("0.0.0.0", PORT)
puts "Serving #{ROOT} on port #{PORT}"

loop do
  socket = server.accept
  begin
    request_line = socket.gets
    next unless request_line
    method, target, = request_line.split(" ", 3)

    while (line = socket.gets)
      break if line == "\r\n"
    end

    if method != "GET" && method != "HEAD"
      body = "Method Not Allowed"
      socket.write("HTTP/1.1 405 Method Not Allowed\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
      next
    end

    path = URI.parse(target).path
    path = "/index.html" if path == "/"
    path = "/404.html" unless path.match?(/\A\/[A-Za-z0-9._\/-]+\z/)
    file = File.expand_path("." + path, ROOT)

    unless file.start_with?(ROOT + File::SEPARATOR) && File.file?(file)
      file = File.join(ROOT, "404.html")
      status = "404 Not Found"
    else
      status = "200 OK"
    end

    body = File.binread(file)
    type = TYPES.fetch(File.extname(file), "application/octet-stream")
    headers = "HTTP/1.1 #{status}\r\nContent-Type: #{type}\r\nContent-Length: #{body.bytesize}\r\nCache-Control: public, max-age=300\r\nConnection: close\r\n\r\n"
    socket.write(headers)
    socket.write(body) if method != "HEAD"
  rescue StandardError => e
    warn e.message
  ensure
    socket.close unless socket.closed?
  end
end
