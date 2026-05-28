# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'My Bootstrap API', type: :request do
  describe 'GET /api/v1/my/bootstrap' do
    it 'creates a default topic and starter entries when user has no topics' do
      user = users(:user_three)

      expect do
        get_json '/api/v1/my/bootstrap', login_user: user
      end.to change(Topic, :count).by(1).and change(Entry, :count).by(2)

      expect(response).to have_http_status(200)
      expect(json_response['bootstrap_created']).to eq(true)

      topic = user.topics.order(created_at: :asc).last
      expect(topic.title).to eq('✨ My First Space')
      expect(topic.is_default).to eq(true)
      expect(json_response['topic']['id']).to eq(topic.id)

      todo_entry = topic.entries.find_by(kind: 'todo')
      expense_entry = topic.entries.find_by(kind: 'expense')

      expect(todo_entry).to be_present
      expect(todo_entry.title).to eq('Welcome to Share-it')
      expect(todo_entry.content).to eq('Tap the checkbox to complete your first task and clear your space.')

      expect(expense_entry).to be_present
      expect(expense_entry.title).to eq('Blue Bottle Coffee')
      expect(expense_entry.content).to eq('Your journey toward mindful tracking starts here.')
      expect(expense_entry.amount).to eq(650)
      expect(expense_entry.currency).to eq('usd')
    end

    it 'does not create bootstrap data when user already has topics' do
      user = users(:user_one)
      existing_topic = user.topics.order(created_at: :asc).first

      expect do
        get_json '/api/v1/my/bootstrap', login_user: user
      end.not_to change(Topic, :count)

      expect(response).to have_http_status(200)
      expect(json_response['bootstrap_created']).to eq(false)
      expect(json_response['topic']['id']).to eq(existing_topic.id)
    end

    it 'is idempotent after bootstrap data is created' do
      user = users(:user_three)
      get_json '/api/v1/my/bootstrap', login_user: user

      topic_count = Topic.count
      entry_count = Entry.count
      get_json '/api/v1/my/bootstrap', login_user: user

      expect(response).to have_http_status(200)
      expect(json_response['bootstrap_created']).to eq(false)
      expect(Topic.count).to eq(topic_count)
      expect(Entry.count).to eq(entry_count)
    end

    it 'returns 401 when not authenticated' do
      get '/api/v1/my/bootstrap'

      expect(response).to have_http_status(401)
    end
  end
end
