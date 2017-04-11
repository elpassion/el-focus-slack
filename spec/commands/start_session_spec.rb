require 'spec_helper'
require_relative '../../commands'
require_relative '../../user'

describe Commands::StartSession do
  subject { described_class.new(conversation, user, time: time) }

  let(:user) { User.create(access_token: access_token, user_id: 'test-user-id') }
  let(:access_token) { 'access-token' }
  let(:time) { nil }
  let(:conversation) { instance_double('Conversation') }

  describe '.try_build' do
    context 'when start message' do
      it 'should build command' do
        expect(described_class.try_build('start', conversation, user))
          .to be_an_instance_of(described_class)
      end

      context 'with numeric argument' do
        it 'should build command' do
          expect(described_class.try_build('start 5', conversation, user))
            .to be_an_instance_of(described_class)
        end
      end

      context 'with not numeric argument' do
        it 'should not build' do
          expect(described_class.try_build('start bad_arg', conversation, user))
            .to be_nil
        end
      end

      context 'when session paused' do
        before do
          user.start_session
          user.pause_session
        end

        it 'should not build' do
          expect(described_class.try_build('start', conversation, user))
            .to be_nil
        end
      end
    end


    context 'when unknown message' do
      it 'should not build' do
        expect(described_class.try_build('stop', conversation, user))
          .to be_nil
      end
    end
  end

  describe '#call' do
    let(:result) { User::SessionUpdateResult.ok }

    before do
      allow(conversation).to receive(:post_message)
      allow(conversation).to receive(:access_token).and_return(access_token)
      allow(conversation).to receive(:channel).and_return('channel')
    end

    it 'should start session' do
      expect(user).to receive(:start_session).and_call_original

      subject.call
    end

    it 'should respond back to user' do
      expect(conversation).to receive(:post_message)

      subject.call
    end

    it 'should schedule SetSnooze job' do
      expect { subject.call }
        .to change(Workers::SetSnoozeWorker.jobs, :size).by(1)
    end

    it 'should schedule Scheduler job' do
      expect { subject.call }
        .to change(Workers::Scheduler.jobs, :size).by(1)
    end

    context 'with time' do
      let(:time) { 5 }

      it 'should start session for given time' do
        expect(user)
          .to receive(:start_session)
                .with(5)
                .and_call_original

        subject.call
      end
    end

    context 'when called twice' do
      it 'should schedule SetSnooze job once' do
        expect { 2.times { subject.call } }
          .to change(Workers::SetSnoozeWorker.jobs, :size).by(1)
      end

      it 'should schedule Scheduler job once' do
        expect { 2.times { subject.call } }
          .to change(Workers::Scheduler.jobs, :size).by(1)
      end
    end

  end
end
