def sway_get_xclients
  require 'json'
  (unwrap = lambda{|n|[n, n['nodes']&.map{|c|unwrap.call(c)}]})
  .call(JSON.parse(`swaymsg -t get_tree`))
  .flatten
  .reject{|n|n&.fetch('window').nil?}
end
puts sway_get_xclients.map{|n|n&.fetch('name')}
