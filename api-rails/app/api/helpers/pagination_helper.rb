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

    # ransack q 파라미터 포함 목록
    def paginated_list(scope, entity_class)
      search = scope.ransack(params[:q])
      results = search.result(distinct: true)
      results = results.order(created_at: :desc) unless params.dig(:q, :s).present?

      total = results.count
      records = paginate(results)
      {
        total: total,
        page: page,
        limit: limit,
        records: entity_class.represent(records)
      }
    end
  end
end