class ChangeTopicsDefaultPermissionsColumnDefault < ActiveRecord::Migration[7.2]
  def up
    # topics.default_permissions 컬럼의 DB 기본값이 ["create","edit"]로 남아있어서,
    # Topic#set_default_permissions(||=)이 새 레코드 초기화 시점에 이미 채워진 이
    # 컬럼 기본값에 막혀 실제로는 한번도 실행되지 않고 있었다. 컬럼 기본값 자체를
    # 새 기본 권한(create edit delete)으로 맞춘다.
    change_column_default :topics, :default_permissions, from: %w[create edit], to: %w[create edit delete]
  end

  def down
    change_column_default :topics, :default_permissions, from: %w[create edit delete], to: %w[create edit]
  end
end
