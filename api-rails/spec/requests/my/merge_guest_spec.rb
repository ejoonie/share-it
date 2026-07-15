# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /api/v1/my/account/merge_guest', type: :request do
  let(:user)  { users(:user_one) }
  let(:guest) { users(:guest_user) }

  def merge(guest_token:, login_user: user)
    post_json '/api/v1/my/account/merge_guest',
              login_user: login_user,
              params: { guest_token: guest_token }
  end

  # ── 정상 케이스 ──────────────────────────────────────────────────────────────

  it '게스트 topics를 현재 계정으로 이전한다' do
    guest_topic = topics(:guest_topic)
    expect(guest_topic.user_id).to eq(guest.id)

    merge(guest_token: guest.token)

    expect(response).to have_http_status(200)
    expect(guest_topic.reload.user_id).to eq(user.id)
  end

  it '게스트 topic_follows를 현재 계정으로 이전한다' do
    guest_follow = topic_follows(:guest_follow)
    expect(guest_follow.user_id).to eq(guest.id)

    merge(guest_token: guest.token)

    expect(guest_follow.reload.user_id).to eq(user.id)
  end

  it '게스트가 작성한 entries의 created_by_id를 현재 계정으로 이전한다' do
    guest_entry = entries(:guest_entry)
    expect(guest_entry.created_by_id).to eq(guest.id)

    merge(guest_token: guest.token)

    expect(guest_entry.reload.created_by_id).to eq(user.id)
  end

  it '게스트가 수정한 entries의 updated_by_id를 현재 계정으로 이전한다' do
    guest_entry = entries(:guest_entry)
    expect(guest_entry.updated_by_id).to eq(guest.id)

    merge(guest_token: guest.token)

    expect(guest_entry.reload.updated_by_id).to eq(user.id)
  end

  it '이전 후 게스트 계정을 삭제한다' do
    guest_id = guest.id

    merge(guest_token: guest.token)

    expect(User.exists?(guest_id)).to be(false)
  end

  it '성공 메시지를 반환한다' do
    merge(guest_token: guest.token)

    expect(json_response['message']).to be_present
  end

  # ── 엣지 케이스 ──────────────────────────────────────────────────────────────

  it '게스트 토픽이 없어도 정상 완료한다' do
    topics(:guest_topic).destroy!

    merge(guest_token: guest.token)

    expect(response).to have_http_status(200)
    expect(User.exists?(guest.id)).to be(false)
  end

  it '게스트 topic_follows가 없어도 정상 완료한다' do
    TopicFollow.where(user: guest).delete_all

    merge(guest_token: guest.token)

    expect(response).to have_http_status(200)
    expect(User.exists?(guest.id)).to be(false)
  end

  it '같은 guest_token으로 두 번 호출하면 두 번째는 404를 반환한다' do
    merge(guest_token: guest.token)
    merge(guest_token: guest.token)

    expect(response).to have_http_status(404)
  end

  # ── 권한/인증 ─────────────────────────────────────────────────────────────────

  it '미인증 상태에서 호출하면 401을 반환한다' do
    post_json '/api/v1/my/account/merge_guest', params: { guest_token: guest.token }

    expect(response).to have_http_status(401)
  end

  it '존재하지 않는 guest_token이면 404를 반환한다' do
    merge(guest_token: 'nonexistent_token')

    expect(response).to have_http_status(404)
  end

  it '일반 유저(is_guest=false)의 토큰이면 404를 반환한다' do
    merge(guest_token: users(:user_two).token)

    expect(response).to have_http_status(404)
  end

  # ── 트랜잭션 ─────────────────────────────────────────────────────────────────

  it 'update 중 오류가 발생하면 topics 이전과 guest 삭제가 롤백된다' do
    guest_topic = topics(:guest_topic)
    guest_id    = guest.id
    original_topic_user_id = guest_topic.user_id

    # 트랜잭션 롤백 검증: destroy! 직전에 오류를 발생시킨다
    allow(guest).to receive(:destroy!).and_raise(ActiveRecord::StatementInvalid, 'simulated DB error')
    # guest 인스턴스를 반환하도록 find_by를 stub
    allow(User).to receive(:find_by).and_call_original
    allow(User).to receive(:find_by).with(token: guest.token, is_guest: true).and_return(guest)

    merge(guest_token: guest.token)

    expect(guest_topic.reload.user_id).to eq(original_topic_user_id)
    expect(User.exists?(guest_id)).to be(true)
  end
end
