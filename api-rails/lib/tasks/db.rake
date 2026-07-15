# db:migrate / db:rollback 후 test DB를 자동으로 동기화
%w[db:migrate db:rollback].each do |task|
  Rake::Task[task].enhance do
    Rake::Task["db:test:prepare"].reenable
    Rake::Task["db:test:prepare"].invoke
  end
end
