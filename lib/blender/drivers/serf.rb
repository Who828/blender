require 'serfx'
require 'blender/exceptions'
require 'blender/log'
require 'blender/drivers/base'

module Blender
  module Driver
    class Serf < Base

      def initialize(events, config)
        @events = events
        @config = config
      end

      def raw_exec(command)
        responses = []
        query, payload = command.split(/\s+/, 2)
        Log.debug("Invoking serf query '#{query}' with payload '#{payload}' against #{@current_host}")
        Log.debug("Serf RPC address #{@config[:host]}:#{@config[:port]}")
        Serfx.connect(host: @config[:host], port: @config[:port]) do |conn|
          conn.query(query, payload, 'FilterNodes'=> [@current_host], 'Timeout'=> 20*1e9.to_i) do |event|
            responses <<  event
          end
        end
        exit_status = responses.size == 1 ? 0 : -1
        ExecOutput.new(exit_status, responses.inspect, '')
      end

      def execute(job)
        tasks = job.tasks
        hosts = job.hosts
        Log.debug("Serf execution tasks [#{tasks.inspect}]")
        Log.debug("Serf query on hosts [#{hosts.inspect}]")
        Array(hosts).each do |host|
          @current_host = host
          Array(tasks).each do |task|
            if evaluate_guards?(task)
              Log.debug("Host:#{host}| Guards are valid")
            else
              Log.debug("Host:#{host}| Guards are invalid")
              run_task_command(task)
            end
          end
        end
      end

      def run_task_command(task)
         e_status = raw_exec(task.command).exitstatus
         if e_status != 0
           if task.metadata[:ignore_failure]
             Log.warn('Ignore failure is set, skipping failure')
           else
            raise Exceptions::ExecutionFailed, "Failed to execute '#{task.command}'"
           end
         end
      end
    end
  end
end