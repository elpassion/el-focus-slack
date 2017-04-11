require 'spec_helper'
require_relative '../../commands'
require_relative '../support/command_shared_examples.rb'

describe Commands::StopSession do
  subject { described_class.new(conversation, user) }

  let(:user) { User.create(access_token: 'access-token', user_id: 'test-user-id') }
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

    it 'should schedule EndSnoozeWorker job' do
      expect { subject.call }
        .to change(Workers::EndSnoozeWorker.jobs, :size).by(1)
    end

    context 'when called twice' do
      it 'should schedule EndSnoozeWorker job once' do
        expect { 2.times { subject.call } }
          .to change(Workers::EndSnoozeWorker.jobs, :size).by(1)
      end
    end
  end
end