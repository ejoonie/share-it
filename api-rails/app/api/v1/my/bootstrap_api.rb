# frozen_string_literal: true

module V1
  module My
    class BootstrapAPI < Grape::API
      helpers ::Helpers::AuthenticationHelper

      # GET /api/v1/my/bootstrap
      desc 'Initialize user with default topic and starter entries'
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
              title: '✨ My First Piggy 🎉',
              is_default: true
            )

            entries << topic.entries.create!(
              created_by: current_user,
              updated_by: current_user,
              kind: 'todo',
              title: 'Review this month’s spending',
              content: 'Check what changed and decide what to adjust together.',
              checked: false
            )

            entries << topic.entries.create!(
              created_by: current_user,
              updated_by: current_user,
              kind: 'expense',
              currency: 'usd',
              amount: 4825,
              title: 'Grocery Run 🛒',
              content: 'Shared expenses are easier when everyone can see the story.',
              checked: false,
              occurred_at: Time.current,
            )

            bootstrap_created = true
          end
        end

        {
          bootstrap_created: bootstrap_created,
          user: Entities::UserEntity.represent(current_user),
          topic: topic ? Entities::TopicEntity.represent(topic) : nil,
          entries: Entities::EntryEntity.represent(entries),
        }
      end
    end
  end
end
