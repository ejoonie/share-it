module Helpers
  module PaginationHelper
    def page
      [params[:page].to_i, 1].max
    end

    def limit
      if params[:limit].blank? # 기본값 20
        20
      else
        [[params[:limit].to_i, 1].max, 500].min # 최대 500
      end
    end

    def paginate(scope)
      offset = (page - 1) * limit
      scope.offset(offset).limit(limit)
    end

    # ransack q 파라미터 포함 목록.
    # entity_options는 Hash 또는 (paginated records를 받는) callable을 받는다 -
    # 읽음 상태처럼 "실제로 이 페이지에 나가는 레코드"에 대해서만 계산해야 하는
    # 값은 callable로 넘기면, 페이지네이션 이후의 records로 계산되어 매 요청마다
    # 전체 scope를 훑는 걸 피할 수 있다 (entries_api.rb의 read_entry_ids 참고).
    def paginated_list(scope, entity_class, entity_options: {})
      search = scope.ransack(params[:q])
      results = search.result(distinct: true)
      results = results.order(created_at: :desc) unless params.dig(:q, :s).present?

      total = results.count
      records = paginate(results)
      resolved_options = entity_options.respond_to?(:call) ? entity_options.call(records) : entity_options
      {
        total: total,
        page: page,
        limit: limit,
        records: entity_class.represent(records, resolved_options)
      }
    end
  end
end