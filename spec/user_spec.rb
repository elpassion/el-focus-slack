require_relative 'spec_helper'

describe User do
  let(:instance) { described_class.create(access_token: 'access_token', user_id: 'user_id') }

  describe '.create' do
    subject { ->(args) { User.create(args) } }

    context 'with :access_token and :user_id' do
      let(:access_token) { 'access_token' }
      let(:args) { { access_token: access_token, user_id: user_id } }
      let(:user_id) { 'user_id' }

      it 'should create User with proper attributes' do
        user = subject.call(args)
        expect(user).to be_an_instance_of described_class
        expect(user.access_token).to eql access_token
        expect(user.send(:user_id)).to eql user_id
      end
    end
  end
end