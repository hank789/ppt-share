window.Users =

  follow: (el) ->
    user_id = $(el).data("id")
    if $("i.fa", el).hasClass("fa-check-circle")
      $.ajax
        url: "/users/#{user_id}/unfollow"
        type: "POST"
      $('span', el).text("关注")
      $("i.fa", el).attr("class", "fa fa-check")
      $(el).attr("data-original-title", "关注")
    else
      $.post "/users/#{user_id}/follow"
      $('span', el).text("取消关注")
      $("i.fa", el).attr("class", "fa fa-check-circle")
      $(el).attr("data-original-title", "取消关注")
    false

  init: ->
    true

$(document).ready ->
  if $('body').data('controller-name') in ['slides', 'replies']
    Users.init()
