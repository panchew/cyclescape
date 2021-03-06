require 'spec_helper'

describe ThreadMailer do
  let(:user)          { create(:user) }
  let(:message_one)   { create(:message, created_by: user) }
  let(:message_two)   { create(:message, created_by: user, in_reply_to: message_one, thread: thread) }
  let(:message_three) { create(:message, created_by: user, in_reply_to: message_two, thread: thread) }
  let(:thread)        { message_one.thread }
  let!(:document)     { create(:document_message, created_by: user, message: message_three, thread: thread) }

  describe 'new document messages' do
    it 'has correct text in email' do
      subject = described_class.send(:common, message_three, user)
      expect(subject.body).to include("http://www.example.com#{document.file.url}")
      expect(subject.body).to include(I18n.t('.thread_mailer.new_document_message.view_the_document'))
      expect(subject.to).to include(user.email)
      expect(subject.header['Reply-To'].value).to eq("<message-#{message_three.public_token}@cyclescape.org>")
      expect(subject.header['Message-ID'].value).to eq("<message-#{message_three.public_token}@cyclescape.org>")
      expect(subject.header['References'].value).to eq(
        "<thread-#{thread.public_token}@cyclescape.org> <message-#{message_one.public_token}@cyclescape.org> <message-#{message_two.public_token}@cyclescape.org>")
    end
  end

  describe 'digest' do
    it do
      subject = described_class.send(:digest, user, {thread => [message_one, message_three]})
      expect(subject.body).to include("http://www.example.com#{document.file.url}")
      expect(subject.body).to include('To reply to the message above')
      expect(subject.subject).to include('Digest for')
      expect(subject.reply_to.first).to include('no-reply')
    end
  end
end
