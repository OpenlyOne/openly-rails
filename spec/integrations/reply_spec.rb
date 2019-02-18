# frozen_string_literal: true

RSpec.describe Reply, type: :model do
  subject(:project) { create :project, :skip_archive_setup }

  describe 'notifications' do
    subject(:reply) do
      create(:reply, contribution: contribution, author: collaborator2)
    end

    let(:contribution) { create(:contribution) }
    let(:replies) do
      [create(:reply, contribution: contribution, author: collaborator1),
       create(:reply, contribution: contribution, author: replier)]
    end
    let(:project)       { contribution.project }
    let(:owner)         { project.owner }
    let(:collaborator1) { create :user }
    let(:collaborator2) { create :user }
    let(:collaborator3) { create :user }
    let(:creator)       { contribution.creator }
    let(:replier)       { create :user }

    before do
      setup
      Notification.delete_all
      ActionMailer::Base.deliveries.clear
    end

    context 'when creating reply' do
      let(:setup) do
        project.collaborators << [collaborator1, collaborator2, collaborator3]
        contribution && replies && contribution.repliers.reload
      end

      before { reply }

      it 'notifies project team, contribution creator, and repliers' do
        expect(Notification.count).to eq 5
        expect(Notification.all.map(&:target)).to match_array(
          [owner, collaborator1, collaborator3, creator, replier].map(&:account)
        )
        expect(Notification.all.map(&:notifier).uniq)
          .to contain_exactly collaborator2
        expect(Notification.all.map(&:notifiable).uniq)
          .to contain_exactly reply
      end

      it 'sends an email to each notification recipient' do
        expect(ActionMailer::Base.deliveries.map(&:to).flatten)
          .to match_array(
            [owner, collaborator1, collaborator3, creator, replier]
            .map(&:account).map(&:email)
          )
      end

      context 'when reply is destroyed' do
        it 'deletes all notifications' do
          expect { reply.destroy }.to change(Notification, :count).to(0)
        end
      end
    end
  end
end
