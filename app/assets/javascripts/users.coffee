window.Users =

  follow : (el) ->
    user_id = $(el).data("id")
    if $("i.icon",el).hasClass("small_followed")
      $.ajax
        url : "/users/#{user_id}/unfollow"
        type : "POST"
      $('span',el).text("关注")
      $("i.icon",el).attr("class","icon small_follow")
      $(el).attr("data-original-title","关注")
    else
      $.post "/users/#{user_id}/follow"
      $('span',el).text("取消关注")
      $("i.icon",el).attr("class","icon small_followed")
      $(el).attr("data-original-title","取消关注")
    false

  init : ->
    true

$(document).ready ->
  if $('body').data('controller-name') in ['slides', 'replies']
    Users.init()
