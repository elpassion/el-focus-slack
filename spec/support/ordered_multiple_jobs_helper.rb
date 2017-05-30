module OrderedMultipleJobsHelper
  def expect_schedule_multiple_jobs(jobs)
    args = Workers::OrderedMultipleJobsWorker.jobs.last.fetch('args')
    expect(args.size).to eql 1
    first_arg = args[0]
    expect(first_arg.size).to eql(jobs.size)
    jobs.each_with_index do |job, index|
      expect(first_arg[index]).to eql({ "job_class" => job[0], "job_arguments" => job[1] })
    end
  end
end
