require 'spec_helper'
require_relative '../../commands'
require_relative '../support/command_shared_examples.rb'
require_relative '../support/ordered_multiple_jobs_helper'

describe Commands::StopSession do
  subject { described_class.new(conversation, user) }

  let(:access_token) { 'access-token' }
  let(:user) { User.create(access_token: access_token, user_id: user_id) }
  let(:user_id) { 'test-user-id' }
  let(:conversation) { instance_double('Conversation') }

  before do
    allow(conversation).to receive(:post_message)
    user.start_session
  end

  it_behaves_like 'a command', 'stop' do
    let(:command) { subject }
  end

  describe '#call' do
    it 'should stop session' do
      expect(user).to receive(:stop_session).and_call_original

      subject.call
    end

    it 'should schedule OrderedMultipleJobs job' do
      subject.call

      self.extend(OrderedMultipleJobsHelper)
      expect_schedule_multiple_jobs([
                                      ['Workers::EndSnoozeWorker', [user_id]],
                                      ['Workers::SetStatusWorker', [user_id, true]],
                                    ])
    end

    context 'when called twice' do
      it 'should schedule EndSnoozeWorker job once' do
        expect { 2.times { subject.call } }
          .to change(Workers::OrderedMultipleJobsWorker.jobs, :size).by(1)
      end
    end
  end
end
