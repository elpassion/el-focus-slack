require 'spec_helper'
require_relative '../../commands'
require_relative '../support/command_shared_examples'
require_relative '../support/ordered_multiple_jobs_helper'

describe Commands::UnpauseSession do
  subject { described_class.new(conversation, user) }

  let(:user) { User.create(access_token: 'access-token', user_id: user_id) }
  let(:user_id) { 'test-user-id' }
  let(:conversation) { instance_double('Conversation') }

  before do
    allow(conversation).to receive(:post_message)
    user.start_session
    user.pause_session
  end

  it_behaves_like 'a command', 'unpause' do
    let(:command) { subject }
  end

  describe '.try_build' do
    context 'when message is start and session is paused' do
      before do
        user.start_session
        user.pause_session
      end

      it 'should build command' do
        expect(described_class.try_build('start', conversation, user))
          .to be_an_instance_of(described_class)
      end
    end
  end

  describe '#call' do
    it "should unpause session" do
      expect(user).to receive(:unpause_session).and_call_original

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
  end
end
