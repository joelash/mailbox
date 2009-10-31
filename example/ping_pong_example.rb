require 'rubygems'
require 'test/unit'

require File.dirname(__FILE__) + "/../lib/mailbox"

class Player
  include Mailbox

  def initialize(sound, send_channel, recieve_channel)
    @sound = sound
    @send_channel = send_channel
    register_channel :recieve_channel, recieve_channel
  end

  mailslot :channel => :recieve_channel
  def play(last_move)
    p "Thread [#{Thread.current.object_id}] - #{@sound} for #{last_move}"
    @send_channel.publish @sound
  end

end

class PingPongExample < Test::Unit::TestCase

  def test_ping_pong
    ping_channel = JRL::Channel.new
    pong_channel = JRL::Channel.new

    pinger = Player.new "ping", ping_channel, pong_channel
    ponger = Player.new "pong", pong_channel, ping_channel

    ping_channel.publish "ping"
    sleep 0.001
  end

end