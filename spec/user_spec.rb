require_relative 'spec_helper'
require_relative '../workers'

describe User do
  let(:access_token) { 'some-access-token' }
  let(:instance) { described_class.create(access_token: access_token, user_id: user_id) }
  let(:user_id) { 'some-user-id' }

  describe '.create' do
    subject { ->(args) { User.create(args) } }

    context 'with :access_token and :user_id' do
      let(:args) { { access_token: access_token, user_id: user_id } }

      it 'should create User with proper attributes' do
        user = subject.call(args)
        expect(user).to be_an_instance_of described_class
        expect(user.access_token).to eql access_token
        expect(user.send(:user_id)).to eql user_id
      end
    end
  end

  describe 'session' do
    describe '#start_session' do
      it 'should create session' do
        expect { instance.start_session }.to change { instance.session.nil? }.from(true).to(false)
      end

      context 'when called twice' do
        it 'should not change session' do
          instance.start_session
          expect { instance.start_session }.to_not change { instance.session }
        end
      end

      context 'when session is paused' do
        before do
          instance.start_session
          instance.pause_session
        end

        it 'should unpause session' do
          expect { instance.start_session }.to change { instance.session_paused? }.from(true).to(false)
        end
      end

      context 'when session is stopped' do
        before do
          instance.start_session
          instance.stop_session
        end

        it 'should create session' do
          expect { instance.start_session }.to change { instance.session.nil? }.from(true).to(false)
        end
      end
    end

    describe '#pause_session' do
      context 'when there is session' do
        before { instance.start_session }

        it 'should pause session' do
          expect { instance.pause_session }.to change { instance.session_paused? }.from(false).to(true)
        end

        context 'when called twice' do
          it 'should not unpause session' do
            instance.pause_session
            expect { instance.pause_session }.to_not change { instance.session }
          end
        end
      end

      context 'when there is no session' do
        it 'should not create session' do
          expect { instance.pause_session }.to_not change { instance.session.nil? }.from(true)
        end
      end
    end

    describe '#stop_session' do
      context 'when there is session' do
        before { instance.start_session }

        it 'should remove session' do
          expect { instance.stop_session }.to change { instance.session.nil? }.from(false).to(true)
        end
      end
    end
  end
end
