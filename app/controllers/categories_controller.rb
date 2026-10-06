class CategoriesController < ApplicationController
  # カテゴリを追加(まだモック。本物は Issue 24)
  # 後ろにグッズを登録の画面を重ねて表示するので、その画面と同じもの(空のグッズ・推し・カテゴリの選択肢)を用意する
  def new
    @item = Item.new
    @characters = Current.user.characters.order(:created_at)
    @categories = Current.user.categories.order(:created_at)
  end
end
