require 'spec_helper'

describe GroupsController, type: :controller do
  let(:group_profile)    { create :quahogcc_group_profile }
  let(:group)            { group_profile.group}
  let(:committee_member) { create(:user).tap { |usr| create(:group_membership, :committee, user: usr, group: group) } }

  describe 'routing' do
    it { is_expected.to route(:get, 'http://subdomain.example.com').to(action: :show) }
    it { is_expected.to route(:get, 'http://subdomain.example.com/overview/search').to(action: :search) }
  end

  context 'when signed in as committee' do
    before do
      warden.set_user committee_member
    end

    describe 'show' do

      subject { get :show, id: group.id }

      it { expect(subject.status).to eq(200) }
    end

    describe 'search', solr: true do
      let!(:in_group)  { create :issue_within_quahog, title: 'Inside the quahog'}
      let!(:by_group)  { create :message_thread, title: 'By quahog', group: group}
      let!(:out_group) { create :issue, title: 'Outside the quahog'}

      subject { get :search, query: 'quahog', id: group.id }

      it 'should have issues inside the group' do
        expect(subject.body).to include('Search Results for Quahog')
        expect(subject.body).to include(in_group.title)
        expect(subject.body).to include(by_group.title)
        expect(subject.body).to_not include(out_group.title)
      end

    end
  end

end

