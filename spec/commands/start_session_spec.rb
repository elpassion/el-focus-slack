require 'spec_helper'
require_relative '../../commands'
require_relative '../../user'
require_relative '../support/ordered_multiple_jobs_helper'

describe Commands::StartSession do
  subject { described_class.new(conversation, user, time: time) }

  let(:user) { User.create(access_token: access_token, user_id: user_id) }
  let(:user_id) { 'test-user-id' }
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
    let(:channel_id) { 'channel-id' }
    let(:result) { User::SessionUpdateResult.ok }

    before do
      allow(conversation).to receive(:post_message)
      allow(conversation).to receive(:access_token).and_return(access_token)
      allow(conversation).to receive(:channel).and_return(channel_id)
    end

    it 'should start session' do
      expect(user).to receive(:start_session).and_call_original

      subject.call
    end

    it 'should respond back to user' do
      expect(conversation).to receive(:post_message)

      subject.call
    end

    it 'should schedule OrderedMultipleJobs job' do
      subject.call
      self.extend(OrderedMultipleJobsHelper)
      expect_schedule_multiple_jobs([
                                      ['Workers::SetSnoozeWorker', [user_id, 25]],
                                      ['Workers::SetStatusWorker', [user_id]],
                                    ])
    end

    it 'should schedule Scheduler job' do
      subject.call
      args = Workers::Scheduler.jobs.last.fetch('args')
      expect(args.size).to eql 1
      expect(args[0]).to eql({ "user_id"                  => user_id,
                               "bot_access_token"         => access_token,
                               "bot_conversation_channel" => channel_id })
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
      it 'should schedule OrderedMultipleJobs job once' do
        expect { 2.times { subject.call } }
          .to change(Workers::OrderedMultipleJobsWorker.jobs, :size).by(1)
      end

      it 'should schedule Scheduler job once' do
        expect { 2.times { subject.call } }
          .to change(Workers::Scheduler.jobs, :size).by(1)
      end
    end

  end
end
