require 'spec_helper'

describe Blender::Lock do
  context 'File based locking' do
    it 'should not allow two blender run with same lockfile to run at the same time' do
      pid1 = fork do
        Blender.blend('test-1') do |sched|
          sched.lock_options('flock', path: '/var/lock/test-1')
          sched.members(['localhost'])
          sched.ruby_task('date') do
            execute do
              sleep 5
              puts 'This will succeed'
            end
          end
        end
      end

      pid2 = fork do
        STDERR.reopen(File::NULL)
        Blender.blend('test-1') do |sched|
          sched.lock_options('flock', path: '/var/lock/test-1')
          sched.members(['localhost'])
          sched.ruby_task('date') do
            execute do
              puts 'This will fail'
            end
          end
        end
      end

      status1 = Process.wait2 pid1
      status2 = Process.wait2 pid2
      expect(status1.last.exitstatus).to eq(0)
      expect(status2.last.exitstatus).to_not eq(0)
    end

    it 'should allow two blender run with different lock file to run at the same time' do
      pid1 = fork do
        Blender.blend('test-1') do |sched|
          sched.lock_options('flock', path: '/var/lock/test-1')
          sched.members(['localhost'])
          sched.ruby_task('date') do
            execute do
              sleep 5
              puts 'This will succeed'
            end
          end
        end
      end

      pid2 = fork do
        Blender.blend('test-2') do |sched|
          sched.lock_options('flock', path: '/var/lock/test-2')
          sched.members(['localhost'])
          sched.ruby_task('date') do
            execute do
              puts 'This will succeed'
            end
          end
        end
      end
      status1 = Process.wait2 pid1
      status2 = Process.wait2 pid2
      expect(status1.last.exitstatus).to eq(0)
      expect(status2.last.exitstatus).to eq(0)
    end

    it 'should raise lock acquisition error when times out' do
      pid1 = fork do
        Blender.blend('test-1') do |sched|
          sched.lock_options('flock', path: '/var/lock/test-1')
          sched.members(['localhost'])
          sched.ruby_task('date') do
            execute do
              sleep 5
              puts 'This will succeed'
            end
          end
        end
      end

      pid2 = fork do
        STDERR.reopen(File::NULL)
        Blender.blend('test-1') do |sched|
          sched.members(['localhost'])
          sched.lock_options('flock', timeout: 3, path: '/var/lock/test-1')
          sched.ruby_task('date') do
            execute do
              puts 'This will fail'
            end
          end
        end
      end
      status1 = Process.wait2 pid1
      status2 = Process.wait2 pid2
      expect(status1.last.exitstatus).to eq(0)
      expect(status2.last.exitstatus).to_not eq(0)
    end

    it 'should not raise lock acquisition error when  able to acquire lock within timeout period' do
      pid1 = fork do
        Blender.blend('test-1') do |sched|
          sched.lock_options('flock', path: '/var/lock/test-1')
          sched.members(['localhost'])
          sched.ruby_task('date') do
            execute do
              sleep 5
              puts 'This will succeed'
            end
          end
        end
      end

      pid2 = fork do
        STDERR.reopen(File::NULL)
        Blender.blend('test-1') do |sched|
          sched.members(['localhost'])
          sched.lock_options('flock', timeout:10, path: '/var/lock/test-1')
          sched.ruby_task('date') do
            execute do
              puts 'This will fail'
            end
          end
        end
      end
      status1 = Process.wait2 pid1
      status2 = Process.wait2 pid2
      expect(status1.last.exitstatus).to eq(0)
      expect(status2.last.exitstatus).to eq(0)
    end
  end
end
