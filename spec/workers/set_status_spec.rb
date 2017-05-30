require 'spec_helper'
require_relative '../../slack_client'
require_relative '../../user'
require_relative '../../workers/set_status_worker'

describe Workers::SetStatusWorker do
  subject { described_class.new.perform(user_id, clear) }

  before do
    User.create(access_token: 'access-token', user_id: user_id)
  end

  let(:user_id) { 'U12345ZN1' }

  context 'with clear=false' do
    let(:clear) { false }

    it 'calls #users_profile_set' do
      expect_call(:users_profile_set, profile: '{"status_text":"","status_emoji":":tomato:"}')
      subject
    end
  end

  context 'with clear=true' do
    let(:clear) { true }

    it 'calls #users_profile_set' do
      expect_call(:users_profile_set, profile: '{"status_text":"","status_emoji":""}')
      subject
    end
  end

  context 'with clear not set' do
    subject { described_class.new.perform(user_id) }

    it 'calls #users_profile_set' do
      expect_call(:users_profile_set, profile: '{"status_text":"","status_emoji":":tomato:"}')
      subject
    end
  end

  def expect_call(call_name, call_args = [])
    slack_client = double(SlackClient)
    expected_call = [call_name, call_args]
    expect(slack_client).to receive(:call).with(*expected_call)
    expect(SlackClient).to receive(:for_user).with(duck_type(:user_id)).and_return(slack_client)
  end
end
