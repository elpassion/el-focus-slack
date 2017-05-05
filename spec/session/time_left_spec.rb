require 'spec_helper'
require_relative '../../session'

describe Session::TimeLeft do
  let(:seconds) { 1480 } # 24:40
  subject { described_class.new(seconds) }

  it 'returns number of seconds left' do
    expect(subject.seconds).to eql(seconds)
    expect(subject.to_i).to eql(seconds)
  end

  it 'returns number of minutes left rounded to top' do
    expect(subject.minutes).to eql(25)
  end
end
