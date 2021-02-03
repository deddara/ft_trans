import consumer from "./consumer"

$(document).on("turbolinks:load", function() {
	$('[data-channel-subscribe="room"]').each(function(index, element) {
	  var $element = $(element),
		  room_id = $element.data('room-id'),
	  messageTemplate = $('[data-role="message-template"]');
  
	  $element.animate({ scrollTop: $element.prop("scrollHeight")}, 1000)        
  
	  var channel = consumer.subscriptions.create(
		{
		  channel: "RoomChannel",
		  room: room_id
		},
		{
		  received: function(data) {
			var year = data.updated_at.substring(0, 10);
			var banned = "ban";
			var muted = "mute";
			var time = data.updated_at.substring(11, 19) + " UTC";
			var content = messageTemplate.children().clone(true, true);
			var current_user = content.find('[data-role="user-id"]').attr('id');
			content.find('[data-role="user-avatar"]').attr('src', data.user_avatar);
			content.find('[data-role="user-id"]').attr('href', function() { return $(this).attr("href") + "/" + data.user_id});
			content.find('[data-role="user-nickname"]').text(data.user_nickname);
			// if (data.user_id == data.current_user_id)
			 if (content.find('[data-role="user-id"]').attr('id') == data.user_id)
				content.find('[data-role="curr_user"]').css('display', 'none');

				for (var i = 0; i < data.banned_users.length; i++) {
					if (data.banned_users[i].id == current_user){
						consumer.subscriptions.remove(channel);
						return;
					}
				}
				console.log(data.blocked_users);

				for (var i = 0; i < data.blocked_users.length; i++) {
					if (data.blocked_users[i].id == current_user){
						return;
					}
				}
				for (var i = 0; i < data.active_users.length; i++) {
					if (data.active_users[i].id == current_user){
						break;
					}

					if ((i + 1) == data.active_users.length){
						consumer.subscriptions.remove(channel);
							return;
					}
				}

			for (var i = 0; i < data.banned_users.length; i++) {
				if (data.banned_users[i].id == data.user_id){
					banned = "unban";
				}
			}
			for (var i = 0; i < data.muted_users.length; i++) {
				if (data.muted_users[i].id == data.user_id){
					muted = "unmute";
				}
			}
			content.find('[data-role="ban-text"]').text(banned);
			content.find('[data-role="ban-href"]').attr('href', "/chat_room_members/" + banned + "?room_id=" + data.room_id + "&user_id=" + data.user_id);
			
			content.find('[data-role="mute-text"]').text(muted);
			content.find('[data-role="mute-href"]').attr('href', "/chat_room_members/" + muted + "?room_id=" + data.room_id + "&user_id=" + data.user_id);

			if (!data.user_guild)
				content.find('[data-role="user-guild"]').css('display', 'hidden');
			else{
				content.find('[data-role="user-guild"]').text('[' + data.user_guild + ']');
				content.find('[data-role="user-guild-id"]').attr('href', function() { return $(this).attr("href") + "/" + data.user_guild_id});
			}
			content.find('[data-role="kick-href"]').attr('href', function() { return $(this).attr("href") + "?room_id=" + data.room_id + "&user_id=" + data.user_id});
			content.find('[data-role="block-href"]').attr('href', function() { return $(this).attr("href") + "?room_id=" + data.room_id + "&blocked_id=" + data.user_id});
			content.find('[data-role="message-text"]').text(data.message);
			content.find('[data-role="message-date"]').text(year + " " + time);
			if (data.message.length != 0)
				$element.append(content);
			$element.animate({ scrollTop: $element.prop("scrollHeight")}, 1000);
		  }
		}
	  );
	});
  });