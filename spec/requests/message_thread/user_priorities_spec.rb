require "spec_helper"

describe "user priorities" do
  let(:thread) { FactoryGirl.create(:message_thread) }

  context "site user prioritise" do
    include_context "signed in as a site user"

    before do
      visit thread_path(thread)
    end

    it "should let you choose a priority" do
      within (".priority-panel") do
        select "Very_high", from: "Priority"
        click_on "Save"
      end

      page.should have_content("Priority saved")
    end

    it "should let you update a priority" do
      within (".priority-panel") do
        select "Very_low", from: "Priority"
        click_on "Save"
      end

      within (".priority-panel") do
        select "Medium", from: "Priority"
        click_on "Save"
      end

      page.should have_content("Priority updated")
    end
  end
end
