# frozen_string_literal: true

module V1
  class MeAPI < Grape::API
    helpers ::Helpers::AuthenticationHelper

    resource :me do
      # GET /api/v1/me/bootstrap
      desc '사용자 부트스트랩'
      get :bootstrap do
        topic = nil
        entries = []
        bootstrap_created = false

        current_user.with_lock do
          if current_user.topics.exists?
            topic = current_user.topics.find_by(is_default: true) || current_user.topics.order(created_at: :asc).first
            entries = topic.entries.order(created_at: :asc).to_a if topic
          else
            topic = current_user.topics.create!(
              user: current_user,
              title: '✨ My First Space',
              is_default: true
            )

            entries << topic.entries.create!(
              created_by: current_user,
              updated_by: current_user,
              kind: 'todo',
              title: 'Welcome to Share-it',
              content: 'Tap the checkbox to complete your first task and clear your space.',
              checked: false
            )
            entries << topic.entries.create!(
              created_by: current_user,
              updated_by: current_user,
              kind: 'expense',
              currency: 'usd',
              amount: 650,
              title: 'Blue Bottle Coffee',
              content: 'Your journey toward mindful tracking starts here.',
              checked: false
            )
            bootstrap_created = true
          end
        end

        {
          bootstrap_created: bootstrap_created,
          topic: topic ? Entities::TopicEntity.represent(topic) : nil,
          entries: Entities::EntryEntity.represent(entries)
        }
      end
    end
  end
end
