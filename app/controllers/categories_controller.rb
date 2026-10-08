class CategoriesController < ApplicationController
  # カテゴリを追加(グッズの画面のシートから。画面は移らず、Turbo Stream でその場にチップと行を足す)
  def create
    @category = Current.user.categories.build(category_params)

    if @category.save
      # 成功:categories/create.turbo_stream.erb で、チップ(選んだ状態)とシートの行を足す
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back_or_to new_good_path, notice: "カテゴリを追加しました" }
      end
    else
      # 失敗(空・同じ名前がある・長すぎる):シートの中にエラーを出す
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("category_errors", partial: "categories/errors", locals: { category: @category }),
                 status: :unprocessable_content
        end
        format.html { redirect_back_or_to new_good_path, alert: @category.errors.full_messages.first }
      end
    end
  end

  # カテゴリを削除(グッズは残して、カテゴリだけ「なし」になる。Category の dependent: :nullify)
  def destroy
    # ログイン中ユーザーのカテゴリの中からだけ探す(ほかの人のカテゴリは見つからず 404)
    @category = Current.user.categories.find(params[:id])
    @category.destroy

    respond_to do |format|
      # 成功:categories/destroy.turbo_stream.erb で、チップとシートの行を消す
      format.turbo_stream
      format.html { redirect_back_or_to new_good_path, status: :see_other, notice: "カテゴリを消去しました" }
    end
  end

  private

  # ストロングパラメーター:カテゴリ名だけ受け取る(持ち主は Current.user.categories で決める)
  def category_params
    params.expect(category: [ :name ])
  end
end
