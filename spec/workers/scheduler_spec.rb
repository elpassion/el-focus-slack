require 'spec_helper'

describe Workers::Scheduler do
  before do
    allow(Workers::Scheduler).to receive(:perform_in).and_return(true)
    allow(user).to receive(:session_paused?).and_return(false)
  end

  let(:access_token) { 'access-token' }
  let(:channel_id) { 'channel-id' }
  let(:user_id) { 'test-user-id' }
  let(:user) { User.create(access_token: access_token, user_id: user_id) }

  subject do
    described_class.new.perform({ "user_id"                  => user_id,
                                  "bot_access_token"         => access_token,
                                  "bot_conversation_channel" => channel_id })
  end

  context 'Scheduler worker is already scheduled' do
    before do
      allow(user).to receive(:scheduled_send_busy_messages_jobs_count).and_return(2)
      expect(User).to receive(:new).and_return(user)
    end

    it 'should do nothing' do
      subject
      expect(Workers::SendImBusyMessageWorker.jobs.size).to eql 0
      expect(Workers::OrderedMultipleJobsWorker.jobs.size).to eql 0
    end
  end

  context 'session in progress' do
    before do
      allow(user).to receive(:session_exists?).and_return(true)
      expect(User).to receive(:new).and_return(user)
      allow_any_instance_of(described_class).to receive(:channels).and_return([double('channel', id: 1234, user: user)])
    end

    it 'should schedule SendImBusyMessage' do
      subject
      expect(Workers::SendImBusyMessageWorker.jobs.size).to eql 1
      expect(Workers::OrderedMultipleJobsWorker.jobs.size).to eql 0
    end
  end

  context 'session already finished' do
    before do
      allow(user).to receive(:session_exists?).and_return(false)
      expect(User).to receive(:new).and_return(user)
    end

    it 'should schedule SendImBusyMessage' do
      subject
      expect(Workers::SendImBusyMessageWorker.jobs.size).to eql 0
      expect(Workers::OrderedMultipleJobsWorker.jobs.size).to eql 1
    end
  end

  context 'session paused' do
    before do
      allow(user).to receive(:session_exists?).and_return(true)
      allow(user).to receive(:session_paused?).and_return(true)
      expect(User).to receive(:new).and_return(user)
    end

    it 'should schedule SendImBusyMessage' do
      subject
      expect(Workers::SendImBusyMessageWorker.jobs.size).to eql 0
      expect(Workers::OrderedMultipleJobsWorker.jobs.size).to eql 0
    end
  end
end
