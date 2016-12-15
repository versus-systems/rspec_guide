require 'dry-monads'
include Dry::Monads::Either::Mixin

module Components
  module Common
    module Persist
      def self.[] model:
        -> (input) {
          if input[model].save
            Right input
          else
            Left input[model].errors.full_messages
          end
        }
      end
    end
  end
end

module Components
  module Common
    module Persist
      describe '.[]' do
        it 'returns a callable' do
          expect(Persist[model: :user]).to respond_to(:call)
        end
      end

      describe '.[]#call' do
        context 'when persisting the model under :user' do
          let(:input) { { user: double(:user, save: save_result) } }
          let(:save_result) { true }

          it 'saves the object in the input under the key :user' do
            expect(input[:user]).to receive(:save)
            Persist[model: :user].call input
          end

          context 'when the save is successful' do
            let(:save_result) { true }

            it 'returns a successful result' do
              expect(Persist[model: :user].call input).to be_success
            end

            it 'returns the input' do
              expect(Persist[model: :user].call(input).value).to eq input
            end
          end

          context 'when the save fails' do
            let(:save_result) { false }
            before { allow(input[:user]).to receive_message_chain('errors.full_messages').and_return :errors }

            it 'returns a failure result' do
              expect(Persist[model: :user].call input).to be_failure
            end

            it 'returns the errors' do
              expect(Persist[model: :user].call(input).value).to eq :errors
            end
          end
        end

        context 'when persisting the model under :game' do
          let(:input) { { game: double(:game, save: save_result) } }
          let(:save_result) { true }

          it 'saves the object in the input under the key :game' do
            expect(input[:game]).to receive(:save)
            Persist[model: :game].call input
          end
        end
      end
    end
  end
end
