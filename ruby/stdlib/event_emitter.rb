module EventEmitter
  def events
    @events ||= Hash.new{ [] }
  end
  def on(event_name, once = false, &callback)
    events[event_name] += [{callback: callback, once: once}]
    nil
  end
  def no_longer_on(event_name, event)
    events[event_name].delete(event)
    nil
  end
  def trigger(event_name, *args)
    events[event_name].each do |c|
      c[:callback].call(*args)
      no_longer_on(event_name, c) if c[:once]
    end
    nil
  end
end

if false
  class Foo
    include EventEmitter
  end

  a = Foo.new
  a.on("asd"){|a| puts a}
  a.events["asd"].first[:callback].call("hi")
  a.on("asd", true){|a| puts "AHH! #{a}"}
  a.trigger("asd", "hi")
  a.trigger("asd", "ho")
end
