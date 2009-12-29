require File.dirname(__FILE__)+"/env"

module Actors
  # /actors/worker
  class Worker
    include Magent::Actor

    expose :echo

    def echo(payload)
      puts payload.inspect
    end
  end
  Magent.register(Worker.new)
end

if $0 == __FILE__
  Magent::Processor.new(Magent.current_actor).run!
end
