module RedXML
  module Server
    module Database
      module Locking
        COMPATIBILITY_MATRIX = {
          #                  IR         NR         LR         SR         IX         CX         SU         SX
          IR: { nil => true, IR: true , NR: true , LR: true , SR: true , IX: true , CX: true , SU: false, SX: false },
          NR: { nil => true, IR: true , NR: true , LR: true , SR: true , IX: true , CX: true , SU: false, SX: false },
          LR: { nil => true, IR: true , NR: true , LR: true , SR: true , IX: true , CX: false, SU: false, SX: false },
          SR: { nil => true, IR: true , NR: true , LR: true , SR: true , IX: false, CX: false, SU: false, SX: false },
          IX: { nil => true, IR: true , NR: true , LR: true , SR: false, IX: true , CX: true , SU: false, SX: false },
          CX: { nil => true, IR: true , NR: true , LR: false, SR: false, IX: true , CX: true , SU: false, SX: false },
          SU: { nil => true, IR: true , NR: true , LR: true , SR: true , IX: false, CX: false, SU: false, SX: false },
          SX: { nil => true, IR: false, NR: false, LR: false, SR: false, IX: false, CX: false, SU: false, SX: false },
        }.freeze


        CONVERSION_MATRIX = {
          #    -             IR       NR       LR         SR         IX         CX         SU       SX
          # IR: {nil => :IR, IR: :IR, NR: :NR, LR: :LR  , SR: :SR  , IX: :IX  , CX: :CX  , SU: :SU, SX: :SX },
          # NR: {nil => :NR, IR: :NR, NR: :NR, LR: :LR  , SR: :SR  , IX: :IX  , CX: :CX  , SU: :SU, SX: :SX },
          # LR: {nil => :LR, IR: :LR, NR: :LR, LR: :LR  , SR: :SR  , IX: :IXNR, CX: :CXNR, SU: :SU, SX: :SX },
          # SR: {nil => :SR, IR: :SR, NR: :SR, LR: :SR  , SR: :SR  , IX: :IXSR, CX: :CXSR, SU: :SR, SX: :SX },
          # IX: {nil => :IX, IR: :IX, NR: :IX, LR: :IXNR, SR: :IXSR, IX: :IX  , CX: :CX  , SU: :SX, SX: :SX },
          # CX: {nil => :CX, IR: :CX, NR: :CX, LR: :CXNR, SR: :CXSR, IX: :CX  , CX: :CX  , SU: :SX, SX: :SX },
          # SU: {nil => :SU, IR: :SU, NR: :SU, LR: :SU  , SR: :SU  , IX: :SX  , CX: :SX  , SU: :SU, SX: :SX },
          # SX: {nil => :SX, IR: :SX, NR: :SX, LR: :SX  , SR: :SX  , IX: :SX  , CX: :SX  , SU: :SX, SX: :SX },
          #    -           IR       NR       LR       SR       IX       CX       SU       SX
          IR: {nil => :IR, IR: :IR, NR: :NR, LR: :LR, SR: :SR, IX: :IX, CX: :CX, SU: :SU, SX: :SX },
          NR: {nil => :NR, IR: :NR, NR: :NR, LR: :LR, SR: :SR, IX: :IX, CX: :CX, SU: :SU, SX: :SX },
          LR: {nil => :LR, IR: :LR, NR: :LR, LR: :LR, SR: :SR, IX: :IX, CX: :CX, SU: :SU, SX: :SX },
          SR: {nil => :SR, IR: :SR, NR: :SR, LR: :SR, SR: :SR, IX: :IX, CX: :CX, SU: :SR, SX: :SX },
          IX: {nil => :IX, IR: :IX, NR: :IX, LR: :IX, SR: :IX, IX: :IX, CX: :CX, SU: :SX, SX: :SX },
          CX: {nil => :CX, IR: :CX, NR: :CX, LR: :CX, SR: :CX, IX: :CX, CX: :CX, SU: :SX, SX: :SX },
          SU: {nil => :SU, IR: :SU, NR: :SU, LR: :SU, SR: :SU, IX: :SX, CX: :SX, SU: :SU, SX: :SX },
          SX: {nil => :SX, IR: :SX, NR: :SX, LR: :SX, SR: :SX, IX: :SX, CX: :SX, SU: :SX, SX: :SX },
        }.freeze


        class LockMode
          attr_reader :mode

          def initialize(mode)
            @mode = mode
          end

          def compatible?(other)
            m1, m2 = @mode, (other ? other.mode : nil)
            COMPATIBILITY_MATRIX[m1][m2]
          end

          def combine_with(lm)
            other = lm ? lm.mode : nil
            @mode = CONVERSION_MATRIX[@mode][other]
            self
          end

          def parent_lock
            mode = {
              IR: :IR,
              NR: :IR,
              LR: :IR,
              SR: :IR,
              IX: :IX,
              CX: :IX,
              SU: :IR,
              SX: :CX,
            }[@mode]
            self.class.new(mode)
          end

          def inspect
            "#{@mode}"
          end
        end
      end
    end
  end
end
