class ChangeUsersNotificationsEnabledDefaultToTrue < ActiveRecord::Migration[7.2]
  def change
    # 새 유저는 알림이 기본으로 켜진 상태로 시작한다. 실제 발송 켜짐/꺼짐은
    # 이 컬럼 하나로만 판단하고(OS 권한 여부와 무관), 클라이언트는 디바이스
    # 토큰을 이 값과 무관하게 항상 등록한다.
    change_column_default :users, :notifications_enabled, from: false, to: true
  end
end
