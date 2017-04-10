require_relative '../../user'

shared_examples 'a command' do |message|
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
    it 'should respond back' do
      expect(conversation).to receive(:post_message)

      command.call
    end
  end
end
