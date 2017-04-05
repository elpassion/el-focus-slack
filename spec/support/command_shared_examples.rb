require_relative '../../user'

shared_examples 'a command' do |message, stub_user_method|
  let(:command) { described_class.new(conversation, user) }
  let(:user) { User.create(access_token: 'access-token', user_id: 'test-user-id') }
  let(:conversation) { instance_double('Conversation') }

  describe '.try_build' do
    context "with #{message} message" do
      it 'should build command' do
        expect(described_class.try_build(message, conversation, user))
          .to be_an_instance_of(described_class)
      end
    end

    context 'with unknown message' do
      it 'should not build command' do
        expect(described_class.try_build('some random message string', conversation, user))
          .to be_nil
      end
    end
  end

  describe '#call' do
    let(:result) { User::SessionUpdateResult.ok }

    before do
      allow(conversation).to receive(:post_message)
      allow(user).to receive(stub_user_method).and_return(result)
    end

    it "should call #{stub_user_method} on user" do
      expect(user).to receive(stub_user_method).and_return(result)

      command.call
    end

    it 'should respond back' do
      expect(conversation).to receive(:post_message)

      command.call
    end
  end
end
