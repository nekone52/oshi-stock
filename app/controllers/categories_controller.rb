class CategoriesController < ApplicationController
  def create
    @category = Current.user.categories.build(category_params)

    if @category.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back_or_to new_good_path, notice: "カテゴリを追加しました" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("category_errors",
                                                   partial: "categories/errors", locals: { category: @category }),
                 status: :unprocessable_content
        end
        format.html { redirect_back_or_to new_good_path, alert: @category.errors.full_messages.first }
      end
    end
  end

  def destroy
    @category = Current.user.categories.find(params[:id])
    @category.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to new_good_path, status: :see_other, notice: "カテゴリを消去しました" }
    end
  end

  private

  def category_params
    params.expect(category: [ :name ])
  end
end
