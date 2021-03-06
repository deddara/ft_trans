class DirectRoom < ApplicationRecord
  belongs_to :user
  has_many :direct_messages, dependent: :destroy, inverse_of: :direct_room
	def is_room_exist(id2)
		case1 = !DirectRoom.where(user_id: id, dude_id: id2).empty?
		case2 = !DirectRoom.where(user_id: id2, dude_id: id).empty?
		case1 || case2
  	end
end
