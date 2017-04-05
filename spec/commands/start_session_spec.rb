require 'spec_helper'
require_relative '../../commands'
require_relative '../../user'

describe Commands::StartSession do
  subject { described_class.new(conversation, user, time: time) }

  let(:user) { User.create(access_token: 'access-token', user_id: 'test-user-id') }
  let(:time) { nil }
  let(:conversation) { instance_double('Conversation') }

  describe '.try_build' do
    context 'when start message' do
      it 'should build command' do
        expect(described_class.try_build('start', conversation, user))
          .to be_an_instance_of(described_class)
      end
    end

    context 'when start with numeric argument' do
      it 'should build command' do
        expect(described_class.try_build('start 5', conversation, user))
          .to be_an_instance_of(described_class)
      end
    end

    context 'when start with not numeric argument' do
      it 'should not build' do
        expect(described_class.try_build('start bad_arg', conversation, user))
          .to be_nil
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
      allow(user).to receive(:start_session).and_return(result)
    end

    it 'should start session' do
      expect(user)
        .to receive(:start_session)
              .with(nil)
              .and_return(result)

      subject.call
    end

    it 'should respond back to user' do
      expect(conversation).to receive(:post_message)

      subject.call
    end

    context 'with time' do
      let(:time) { 5 }

      it 'should start session for given time' do
        expect(user)
          .to receive(:start_session)
                .with(5)
                .and_return(result)

        subject.call
      end
    end
  end
end
