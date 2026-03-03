# frozen_string_literal: true

RSpec.describe RrxJobs do
  it "has a version number" do
    expect(RrxJobs::VERSION).not_to be nil
  end

  it 'exposes the gem version' do
    expect(RrxJobs::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
