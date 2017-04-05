require 'spec_helper'
require_relative '../../commands'
require_relative '../support/command_shared_examples.rb'

describe Commands::StopSession do
  it_behaves_like 'a command', 'stop', :stop_session
end
