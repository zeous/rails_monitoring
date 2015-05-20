require 'socket'
require 'json'

class MainController < ApplicationController
  layout "main"
  def index

  end
  def health_check
  	response_json = send_protocol('ping')
  	response_hash = JSON.parse(response_json)
  	@master_host = RailsMonitoring::Application.config.master_host
  	@master_port = RailsMonitoring::Application.config.master_port
  	if(response_hash["responseCode"] == 200)
  		@is_master_live = true
	else
		@is_master_live = false
	end
  end

  private
  def send_protocol (message)
  	msg_hash = {:protocol=> message}
  	send_msg = JSON.generate(msg_hash)
  	begin
	  	timeout(10) do
	  		host = RailsMonitoring::Application.config.master_host
	  		port = RailsMonitoring::Application.config.master_port
	  		socket_server = TCPSocket.new(host ,port)
			msg_pack = [send_msg.length].pack("N")
			socket_server.write(msg_pack)
			socket_server.write(send_msg)
			response_size = socket_server.read(4)
			response_size = response_size.unpack('N')[0]
			response = socket_server.read(response_size)
			return response
		end
	rescue Errno::ECONNREFUSED
		return '{"responseCode": 500}'
	rescue Timeout::Error
    	return '{"responseCode": 500}'
    end
  end
end
