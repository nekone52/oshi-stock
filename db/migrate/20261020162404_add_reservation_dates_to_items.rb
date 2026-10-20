class AddReservationDatesToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :reservation_start_on, :date
    add_column :items, :reservation_deadline_on, :date
  end
end
