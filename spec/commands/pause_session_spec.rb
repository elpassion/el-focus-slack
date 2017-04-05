require 'spec_helper'
require_relative '../../commands'
require_relative '../support/command_shared_examples'

describe Commands::PauseSession do
  it_behaves_like 'a command', 'pause', :pause_session
end
