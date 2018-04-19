function openssl_gen_selfsigned_key
  openssl req -sha256 -nodes -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
end
