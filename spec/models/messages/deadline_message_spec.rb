# == Schema Information
#
# Table name: deadline_messages
#
#  id                :integer          not null, primary key
#  thread_id         :integer          not null
#  message_id        :integer          not null
#  created_by_id     :integer          not null
#  deadline          :datetime         not null
#  title             :string(255)      not null
#  created_at        :datetime
#  invalidated_at    :datetime
#  invalidated_by_id :integer
#

require 'spec_helper'

describe DeadlineMessage do
  describe 'associations' do
    it { is_expected.to belong_to(:thread) }
    it { is_expected.to belong_to(:message) }
    it { is_expected.to belong_to(:created_by) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:deadline) }
    it { is_expected.to validate_presence_of(:title) }
  end

  it 'should email about deadlines' do
    dm = create :deadline_message, deadline: 5.hours.from_now
    thread = dm.thread
    subscription = create :thread_subscription, thread: thread
    user = subscription.user
    user.prefs.update_column(:email_status_id, 1)

    expect{described_class.email_upcomming_deadlines!}.to change{ all_emails.count }.by(1)
    email = all_emails.last
    expect(email.to).to include(user.email)
    expect(email.body).to include("upcoming deadline")
    expect(email.subject).to include("Upcoming deadline")
    expect(email.body).to include(dm.deadline.to_formatted_s(:long_ordinal))
  end
end
