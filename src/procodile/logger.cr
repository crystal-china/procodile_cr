require "./color"

module Procodile
  class_getter mutex = Mutex.new

  def self.log(color : Int32?, name : String, text : String)
    mutex.synchronize do
      text.each_line do |message|
        STDOUT << "#{Time.local.to_s("%H:%M:%S")} #{name.ljust(18, ' ')} | ".color(color)
        STDOUT << message
        STDOUT << "\n"
      end
      STDOUT.flush
    end
  end
end
