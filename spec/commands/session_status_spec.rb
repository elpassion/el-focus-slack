require 'spec_helper'
require_relative '../../commands'
require_relative '../support/command_shared_examples.rb'

describe Commands::SessionStatus do
  subject { described_class.new(conversation, user) }

  let(:user) { User.create(access_token: 'access-token', user_id: 'test-user-id') }
  let(:conversation) { instance_double('Conversation') }
  let(:time_left) { Session::TimeLeft.new(25 * 60) }

  before do
    allow(conversation).to receive(:post_message)
    user.start_session
  end

  it_behaves_like 'a command', 'status' do
    let(:command) { subject }
  end

  it 'sends message with time left' do
    allow(user).to receive(:session_time_left).and_return(time_left)
    expect(conversation).to receive(:post_message).with('25 minutes left in session :timer_clock:')
    subject.call
  end

  context 'when session paused' do
    before { user.pause_session }

    it 'sends messages that session is paused' do
      expect(conversation).to receive(:post_message).with('Session paused :stopwatch:')
      subject.call
    end
  end

  context 'when session stopped' do
    before { user.stop_session }

    it 'sends message that no session is in progress' do
      expect(conversation).to receive(:post_message).with('No session in progress :coffee:')
      subject.call
    end
  end
end
