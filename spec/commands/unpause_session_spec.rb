require 'spec_helper'
require_relative '../../commands'
require_relative '../support/command_shared_examples'

describe Commands::UnpauseSession do
  it_behaves_like 'a command', 'unpause', :unpause_session
end
