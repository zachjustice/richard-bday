class FixAudienceDbConstraints < ActiveRecord::Migration[8.0]
  def up
    # The unique index on [room_id, name] contradicts the model's
    # `unless: :audience?` on name uniqueness validation — audience members
    # can share names, so restrict the DB constraint to non-audience users.
    remove_index :users, name: "index_users_on_room_id_and_name"
    add_index :users, [ :room_id, :name ], unique: true,
      where: "role != 'Audience'",
      name: "index_users_on_room_id_and_name"
  end

  def down
    remove_index :users, name: "index_users_on_room_id_and_name"
    add_index :users, [ :room_id, :name ], unique: true,
      name: "index_users_on_room_id_and_name"
  end
end
