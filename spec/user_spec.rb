require_relative 'spec_helper'
require_relative '../workers'

describe User do
  let(:access_token) { 'some-access-token' }
  let(:instance) { described_class.create(access_token: access_token, user_id: user_id) }
  let(:user_id) { 'some-user-id' }

  describe '.create' do
    subject { ->(args) { User.create(args) } }

    context 'with :access_token and :user_id' do
      let(:args) { { access_token: access_token, user_id: user_id } }

      it 'should create User with proper attributes' do
        user = subject.call(args)
        expect(user).to be_an_instance_of described_class
        expect(user.access_token).to eql access_token
        expect(user.send(:user_id)).to eql user_id
      end
    end
  end

  describe 'session' do
    let(:channel_1) { double('channel', id: channel_1_id, user: interlocutor_1_id) }
    let(:channel_2) { double('channel', id: channel_2_id, user: interlocutor_2_id) }
    let(:channel_1_id) { 'CHANNEL#1' }
    let(:channel_2_id) { 'CHANNEL#2' }
    let(:interlocutor_1_id) { 'INTERLOCUTOR#1' }
    let(:interlocutor_2_id) { 'INTERLOCUTOR#2' }

    describe '#start_session' do
      let(:respond_with_im_busy_jobs_count) { -> { Workers::RespondWithImBusyWorker.jobs.size } }
      let(:set_snooze_jobs_count) { -> { Workers::SetSnoozeWorker.jobs.size } }
      let(:end_snooze_jobs_count) { -> { Workers::EndSnoozeWorker.jobs.size } }

      it 'should schedule RespondWithImBusyWorker job' do
        expect { instance.start_session }.to change { respond_with_im_busy_jobs_count.call }.from(0).to(1)
      end

      it 'should schedule SetSnooze job' do
        expect { instance.start_session }.to change { set_snooze_jobs_count.call }.from(0).to(1)
      end

      it 'should create session' do
        expect { instance.start_session }.to change { instance.session.nil? }.from(true).to(false)
      end

      context 'when called twice' do
        it 'should schedule RespondWithImBusyWorker job only once' do
          expect { 2.times { instance.start_session } }.to change { respond_with_im_busy_jobs_count.call }.from(0).to(1)
        end

        it 'should schedule SetSnooze job only once' do
          expect { 2.times { instance.start_session } }.to change { set_snooze_jobs_count.call }.from(0).to(1)
        end

        it 'should not change session' do
          instance.start_session
          expect { instance.start_session }.to_not change { instance.session }
        end
      end

      context 'when session is paused' do
        before do
          instance.start_session
          instance.pause_session
        end

        it 'should not schedule RespondWithImBusyWorker job' do
          expect { instance.start_session }.to_not change { respond_with_im_busy_jobs_count.call }.from(1)
        end

        it 'should schedule SetSnooze job' do
          expect { instance.start_session }.to change { set_snooze_jobs_count.call }.from(1).to(2) # we don't clear jobs, so we must use #from(1) instead of #from(0) (first job is scheduled in before block)
        end

        it 'should unpause session' do
          expect { instance.start_session }.to change { instance.session_paused? }.from(true).to(false)
        end
      end

      context 'when session is stopped' do
        before do
          instance.start_session
          instance.stop_session
        end

        it 'should schedule RespondWithImBusyWorker job' do
          expect { instance.start_session }.to change { respond_with_im_busy_jobs_count.call }.from(1).to(2) # we don't clear jobs, so we must use #from(1) instead of #from(0) (first job is scheduled in before block)
        end

        it 'should schedule SetSnooze job' do
          expect { instance.start_session }.to change { set_snooze_jobs_count.call }.from(1).to(2) # we don't clear jobs, so we must use #from(1) instead of #from(0) (first job is scheduled in before block)
        end

        it 'should create session' do
          expect { instance.start_session }.to change { instance.session.nil? }.from(true).to(false)
        end
      end
    end

    describe '#pause_session' do
      let(:end_snooze_jobs_count) { -> { Workers::EndSnoozeWorker.jobs.size } }

      context 'when there is session' do
        before { instance.start_session }

        it 'should schedule EndSnooze job' do
          expect { instance.pause_session }.to change { end_snooze_jobs_count.call }.from(0).to(1)
        end

        it 'should pause session' do
          expect { instance.pause_session }.to change { instance.session_paused? }.from(false).to(true)
        end

        context 'when called twice' do
          it 'should schedule SetSnooze job only once' do
            expect { 2.times { instance.pause_session } }.to change { end_snooze_jobs_count.call }.from(0).to(1)
          end

          it 'should not unpause session' do
            instance.pause_session
            expect { instance.pause_session }.to_not change { instance.session }
          end
        end
      end

      context 'when there is no session' do
        it 'should not schedule any job' do
          expect { instance.pause_session }.to_not change { Sidekiq::Worker.jobs.count }.from(0)
        end

        it 'should not create session' do
          expect { instance.pause_session }.to_not change { instance.session.nil? }.from(true)
        end
      end
    end

    describe '#stop_session' do
      let(:end_snooze_jobs_count) { -> { Workers::EndSnoozeWorker.jobs.size } }

      context 'when there is session' do
        before { instance.start_session }

        it 'should schedule EndSnooze job' do
          expect { instance.stop_session }.to change { end_snooze_jobs_count.call }.from(0).to(1)
        end

        it 'should remove session' do
          expect { instance.stop_session }.to change { instance.session.nil? }.from(false).to(true)
        end

        context 'when called twice' do
          it 'should schedule EndSnooze job only once' do
            expect { 2.times { instance.stop_session } }.to change { end_snooze_jobs_count.call }.from(0).to(1)
          end
        end
      end

      context 'when there is no session' do
        it 'should not schedule any job' do
          expect { instance.stop_session }.to_not change { Sidekiq::Worker.jobs.count }.from(0)
        end
      end
    end
  end
end
