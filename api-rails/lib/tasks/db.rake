# db:migrate / db:rollback 후 test DB에 마이그레이션을 직접 실행해 동기화한다.
# db:test:prepare / db:test:load_schema 는 둘 다 db:test:purge (DROP → recreate) 를 호출하므로
# 서버가 development DB에 연결 중일 때 PG::ObjectInUse 에러가 난다.
# ActiveRecord::MigrationContext 로 purge 없이 migrate 만 실행해 이를 우회한다.
%w[db:migrate db:rollback].each do |task|
  Rake::Task[task].enhance do
    ActiveRecord::Base.establish_connection(:test)
    ActiveRecord::MigrationContext.new(
      Rails.root.join('db/migrate').to_s,
      ActiveRecord::SchemaMigration.new(ActiveRecord::Base.connection_pool)
    ).migrate
    ActiveRecord::Base.establish_connection(Rails.env.to_sym)
  end
end
