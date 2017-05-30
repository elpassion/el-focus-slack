require 'spec_helper'
require_relative '../conversation'

describe Conversation do
  subject { described_class.new(client, channel) }
  let(:client) { double('client') }
  let(:channel) { 'CHANNEL' }

  describe '#post_message' do
    let(:message) { 'message' }

    it 'should post message to channel' do
      expect(client)
        .to receive(:call)
              .with(:chat_postMessage, text: message, channel: channel)

      subject.post_message(message)
    end
  end
end
