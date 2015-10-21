# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require 'spec_helper'

describe Event::ListsController do

  before { sign_in(user) }

  subject { assigns(:camps).values.flatten }

  describe 'GET all_camps' do

    context 'as bulei' do
      let(:user) { people(:bulei) }

      before do
        now = Time.zone.now
        @current = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: true, state: 'closed')
        @current.dates = [Fabricate(:event_date, start_at: now - 15.days, finish_at: now - 10.days),
                          Fabricate(:event_date, start_at: now - 5.days, finish_at: now + 5.days)]
        @upcoming = Fabricate(:pbs_camp, groups: [groups(:zh)], camp_submitted: true, state: 'confirmed')
        @upcoming.dates = [Fabricate(:event_date, start_at: now + 10.days, finish_at: nil),
                           Fabricate(:event_date, start_at: now + 12.days, finish_at: nil)]
        @upcoming2 = Fabricate(:pbs_camp, groups: [groups(:zh)], camp_submitted: true, state: 'created')
        @upcoming2.dates = [Fabricate(:event_date, start_at: now + 18.days, finish_at: now + 30.days),
                            Fabricate(:event_date, start_at: now + 50.days, finish_at: now + 55.days)]
        past = Fabricate(:pbs_camp, groups: [groups(:zh)], camp_submitted: true, state: 'confirmed')
        past.dates = [Fabricate(:event_date, start_at: now - 5.days, finish_at: nil)]
        canceled = Fabricate(:pbs_camp, groups: [groups(:zh)], camp_submitted: true, state: 'canceled')
        canceled.dates = [Fabricate(:event_date, start_at: now + 5.days, finish_at: nil)]
        unsubmitted = Fabricate(:pbs_camp, groups: [groups(:zh)], camp_submitted: false, state: 'confirmed')
        unsubmitted.dates = [Fabricate(:event_date, start_at: now + 5.days, finish_at: nil)]
        future = Fabricate(:pbs_camp, groups: [groups(:zh)], camp_submitted: true, state: 'confirmed')
        future.dates = [Fabricate(:event_date, start_at: now + 50.days, finish_at: nil)]
      end

      it 'contains only current and upcoming camps' do
        get :all_camps
        is_expected.to eq([@current, @upcoming, @upcoming2])
      end
    end

    context 'as abteilungsleitung' do
      let(:user) { people(:al_schekka) }

      it 'is not allowed' do
        expect { get :all_camps }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'GET kantonalverband_camps' do

    context 'as kantonsleitung' do
      let(:user) { Fabricate(Group::Kantonalverband::Kantonsleitung.name, group: groups(:be)).person }

      before do
        now = Time.zone.now
        @current = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: true, state: 'closed')
        @current.dates = [Fabricate(:event_date, start_at: now - 15.days, finish_at: now - 10.days),
                          Fabricate(:event_date, start_at: now - 5.days, finish_at: now + 5.days)]
        @early = Fabricate(:pbs_camp, groups: [groups(:be)], camp_submitted: true, state: 'confirmed')
        @early.dates = [Fabricate(:event_date, start_at: Date.new(now.year, 3, 1), finish_at: Date.new(now.year, 3, 10))]
        @late = Fabricate(:pbs_camp, groups: [groups(:bern)], camp_submitted: true, state: 'confirmed')
        @late.dates = [Fabricate(:event_date, start_at: Date.new(now.year, 12, 1))]
        created = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: true, state: 'created')
        created.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        canceled = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: true, state: 'canceled')
        canceled.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        unsubmitted = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: false, state: 'confirmed')
        unsubmitted.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        future = Fabricate(:pbs_camp, groups: [groups(:be)], camp_submitted: true, state: 'confirmed')
        future.dates = [Fabricate(:event_date, start_at: now + 1.year, finish_at: nil)]
        other = Fabricate(:pbs_camp, groups: [groups(:zh)], camp_submitted: true, state: 'confirmed')
        other.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
      end

      it 'contains all camps in all subgroups this year' do
        get :kantonalverband_camps, group_id: groups(:be).id
        is_expected.to match_array([@current, @early, @late])
      end

    end

    context 'as bulei' do
      let(:user) { people(:bulei) }

      it 'is not allowed' do
        expect { get :kantonalverband_camps, group_id: groups(:be).id }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'GET camps_in_canton' do

    context 'as krisenverantwortung' do
      let(:user) { Fabricate(Group::Kantonalverband::VerantwortungKrisenteam.name, group: groups(:be)).person }

      before do
        now = Time.zone.now
        groups(:be).update!(cantons: %w(be fr))

        @current = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: true, state: 'closed', canton: 'be')
        @current.dates = [Fabricate(:event_date, start_at: now - 15.days, finish_at: now - 10.days),
                          Fabricate(:event_date, start_at: now - 5.days, finish_at: now + 5.days)]
        @upcoming = Fabricate(:pbs_camp, groups: [groups(:chaeib)], camp_submitted: true, state: 'confirmed', canton: 'be')
        @upcoming.dates = [Fabricate(:event_date, start_at: now + 18.days, finish_at: now + 30.days),
                           Fabricate(:event_date, start_at: now + 50.days, finish_at: now + 55.days)]
        created = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: true, state: 'created', canton: 'be')
        created.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        canceled = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: true, state: 'canceled', canton: 'be')
        canceled.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        unsubmitted = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: false, state: 'confirmed', canton: 'be')
        unsubmitted.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        future = Fabricate(:pbs_camp, groups: [groups(:be)], camp_submitted: true, state: 'confirmed', canton: 'be')
        future.dates = [Fabricate(:event_date, start_at: now + 1.year, finish_at: nil)]
        other = Fabricate(:pbs_camp, groups: [groups(:zh)], camp_submitted: true, state: 'confirmed', canton: 'zh')
        other.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
      end

      it 'contains all upcoming camps in this canton' do
        get :camps_in_canton, canton: 'be'
        is_expected.to match_array([@current, @upcoming])
      end

    end

  end

  describe 'GET camps_abroad' do
    context 'as ko int' do
      let(:user) { Fabricate(Group::Bund::InternationalCommissionerIcWagggs.name, group: groups(:bund)).person }

      before do
        now = Time.zone.now
        @current = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: true, state: 'closed', canton: 'zz')
        @current.dates = [Fabricate(:event_date, start_at: now - 15.days, finish_at: now - 10.days),
                          Fabricate(:event_date, start_at: now - 5.days, finish_at: now + 5.days)]
        @early = Fabricate(:pbs_camp, groups: [groups(:be)], camp_submitted: true, state: 'confirmed', canton: 'zz')
        @early.dates = [Fabricate(:event_date, start_at: Date.new(now.year, 3, 1), finish_at: Date.new(now.year, 3, 10))]
        created = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: true, state: 'created', canton: 'zz')
        created.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        canceled = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: true, state: 'canceled', canton: 'zz')
        canceled.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        unsubmitted = Fabricate(:pbs_camp, groups: [groups(:schekka)], camp_submitted: false, state: 'confirmed', canton: 'zz')
        unsubmitted.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        future = Fabricate(:pbs_camp, groups: [groups(:be)], camp_submitted: true, state: 'confirmed', canton: 'zz')
        future.dates = [Fabricate(:event_date, start_at: now + 1.year, finish_at: nil)]
        other = Fabricate(:pbs_camp, groups: [groups(:zh)], camp_submitted: true, state: 'confirmed', canton: 'be')
        other.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
        empty = Fabricate(:pbs_camp, groups: [groups(:zh)], camp_submitted: true, state: 'confirmed')
        empty.dates = [Fabricate(:event_date, start_at: now, finish_at: nil)]
      end

      it 'contains all abroad camps this year' do
        get :camps_abroad
        is_expected.to match_array([@current, @early])
      end

    end
  end
end