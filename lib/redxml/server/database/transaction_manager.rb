require 'monitor'
require 'singleton'
require 'redxml/server/database/locking'

module RedXML
  module Server
    module Database
      class TransactionManager
        include MonitorMixin
        include Singleton

        attr_reader :locks

        def self.generate_id
          "#{Thread.current.object_id}-#{Time.now.to_f}"
        end

        def initialize
          super()
          @transaction_map = {}
          @locks = {}
        end

        def transaction
          synchronize do
            id = self.class.generate_id
            @transaction_map[id] = Transaction.new(self, id)
          end
        end

        def release(transaction)
          synchronize do
            t = @transaction_map.delete(transaction.id)
            t.release_locks
          end
        end
      end

      class Transaction
        include MonitorMixin
        include Locking

        attr_reader :id, :manager

        def initialize(manager, id)
          super()
          @id      = id
          @manager = manager
          @locks   = {}
        end

        def acquire_lock(node, lock)
          synchronize do
            lock_mode = LockMode.new(lock)

            lock_parents(node.parent, lock_mode.parent_lock)
            lock_request(node, lock_mode)
          end
        end

        def release_locks
          @locks.each do |node, _lock|
            manager.locks.delete(node)
          end
        end

        private

        def set_lock(cn, lm)
          synchronize do
            cn_lock = manager.locks[cn]
            manager.locks[cn] = if cn_lock
                                  cn_lock.combine_with(lm)
                                else
                                  lm
                                end
          end
        end

        def lock_request(cn, lm)
          cn_lock = manager.locks[cn]
          if lm.compatible? cn_lock
            set_lock(cn, lm)
            @locks[cn] = lm
          else
            wait_for(cn)
          end
        end

        def wait_for(node, timeout = 10)
          synchronize do
            n = 0
            while @manager.locks[node]
              wait(0.1)
              n += 1
              fail "Transaction #{@id} timed out" if n >= timeout
            end
          end
        end

        def lock_parents(cn, lm)
          while cn
            lock_request(cn, lm)
            lm = lm.parent_lock
            cn = cn.parent
          end
        end
      end
    end
  end
end
