cert_path = ENV['DOCKER_CLIENT_CERT_PATH']
return unless cert_path

Docker.options = {
  client_cert: File.join(cert_path, 'cert.pem'),
  client_key: File.join(cert_path, 'key.pem'),
  ssl_ca_file: File.join(cert_path, 'ca.pem'),
  scheme: 'https'
}