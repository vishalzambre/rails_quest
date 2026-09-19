class AddTwitterHandleToConferenceEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :conference_events, :twitter_handle, :string
  end
end
