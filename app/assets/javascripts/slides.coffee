# SlidesController 下所有页面的 JS 功能
window.Slides =
  replies_per_page: 50

  # 往话题编辑器里面插入图片代码
  appendImageFromUpload : (srcs) ->
    txtBox = $(".slide_editor")
    caret_pos = txtBox.caret('pos')
    src_merged = ""
    for src in srcs
      src_merged = "![](#{src})\n"
    source = txtBox.val()
    before_text = source.slice(0, caret_pos)
    txtBox.val(before_text + src_merged + source.slice(caret_pos+1, source.count))
    txtBox.caret('pos',caret_pos + src_merged.length)
    txtBox.focus()

  # 上传图片
  initUploader : () ->
    $("#slide_add_image").bind "click", () ->
      $(".slide_editor").focus()
      $("#slide_upload_images").click()
      return false

    opts =
      url : "/photos"
      type : "POST"
      beforeSend : () ->
        $("#slide_add_image").hide()
        $("#slide_add_image").before("<span class='loading'>上传中...</span>")
      success : (result, status, xhr) ->
        $("#slide_add_image").parent().find("span.loading").remove()
        $("#slide_add_image").show()
        Slides.appendImageFromUpload([result])

    $("#slide_upload_images").fileUpload opts
    return false

  # 回复
  reply : (floor,login) ->
    reply_body = $("#reply_body")
    new_text = "##{floor}楼 @#{login} "
    if reply_body.val().trim().length == 0
      new_text += ''
    else
      new_text = "\n#{new_text}"
    reply_body.focus().val(reply_body.val() + new_text)
    return false

  # Given floor, calculate which page this floor is in
  pageOfFloor: (floor) ->
    Math.floor((floor - 1) / Slides.replies_per_page) + 1

  # 跳到指定楼。如果楼层在当前页，高亮该层，否则跳转到楼层所在页面并添
  # 加楼层的 anchor。返回楼层 DOM Element 的 jQuery 对象
  #
  # -   floor: 回复的楼层数，从1开始
  gotoFloor: (floor) ->
    replyEl = $("#reply#{floor}")

    if replyEl.length > 0
      Slides.highlightReply(replyEl)
    else
      page = Slides.pageOfFloor(floor)
      # TODO: merge existing query string
      url = window.location.pathname + "?page=#{page}" + "#reply#{floor}"
      App.gotoUrl url

    replyEl

  # 高亮指定楼。取消其它楼的高亮
  #
  # -   replyEl: 需要高亮的 DOM Element，须要 jQuery 对象
  highlightReply: (replyEl) ->
    $("#replies .reply").removeClass("light")
    replyEl.addClass("light")

  # 异步更改用户 like 过的回复的 like 按钮的状态
  checkRepliesLikeStatus : (user_liked_reply_ids) ->
    for id in user_liked_reply_ids
      el = $("#replies a.likeable[data-id=#{id}]")
      App.likeableAsLiked(el)

  # Ajax 回复后的事件
  replyCallback : (success, msg) ->
    $("#main .alert-message").remove()
    if success
      $("abbr.timeago",$("#replies .reply").last()).timeago()
      $("abbr.timeago",$("#replies .total")).timeago()
      $("#new_reply textarea").val('')
      $("#preview").text('')
      App.notice(msg,'#new_reply')
    else
      App.alert(msg,'#new_reply')
    $("#new_reply textarea").focus()
    $('#btn_reply').button('reset')

  preview: (body) ->
    $("#preview").text "Loading..."

    $.post "/slides/preview",
      "body": body,
      (data) ->
        $("#preview").html data.body
      "json"

  hookPreview: (switcher, textarea) ->
    # put div#preview after textarea
    preview_box = $(document.createElement("div")).attr "id", "preview"
    preview_box.addClass("markdown_body")
    $(textarea).after preview_box
    preview_box.hide()

    $(".edit a",switcher).click ->
      $(".preview",switcher).removeClass("active")
      $(this).parent().addClass("active")
      $(preview_box).hide()
      $(textarea).show()
      false
    $(".preview a",switcher).click ->
      $(".edit",switcher).removeClass("active")
      $(this).parent().addClass("active")
      $(preview_box).show()
      $(textarea).hide()
      Slides.preview($(textarea).val())
      false

  initCloseWarning: (el, msg) ->
    return false if el.length == 0
    msg = "离开本页面将丢失未保存页面!" if !msg
    $("input[type=submit]").click ->
      $(window).unbind("beforeunload")
    el.change ->
      if el.val().length > 0
        $(window).bind "beforeunload", (e) ->
          if $.browser.msie
            e.returnValue = msg
          else
            return msg
      else
        $(window).unbind("beforeunload")

  favorite : (el) ->
    slide_id = $(el).data("id")
    if $("i.icon",el).hasClass("small_bookmarked")
      hash =
        type : "unfavorite"
      $.ajax
        url : "/slides/#{slide_id}/favorite"
        data : hash
        type : "POST"
      $('span',el).text("收藏")
      $("i.icon",el).attr("class","icon small_bookmark")
    else
      $.post "/slides/#{slide_id}/favorite"
      $('span',el).text("取消收藏")
      $("i.icon",el).attr("class","icon small_bookmarked")
    false

  follow : (el) ->
    slide_id = $(el).data("id")
    followed = $(el).data("followed")
    if followed
      $.ajax
        url : "/slides/#{slide_id}/unfollow"
        type : "POST"
      $(el).data("followed", false)
      $("i",el).attr("class", "icon small_follow")
    else
      $.ajax
        url : "/slides/#{slide_id}/follow"
        type : "POST"
      $(el).data("followed", true)
      $("i",el).attr("class", "icon small_followed")
    false

  download : (el) ->
    attach_id = $(el).data("id")
    $.ajax
      url : "/attachs/#{attach_id}/download"
      type : "GET"
      success : (data) ->
        alert(data)
    false

  carousel : (attach_id) -> 
    $.ajax
      url : "/attachs/#{attach_id}/carsouel"
      type : "POST"
      success : (data) ->
        $("#upload_landing").remove()
      failure : (e) ->
        alert(e)

  submitTextArea : (el) ->
    if $(el.target).val().trim().length > 0
      $("#reply > form").submit()
    return false

  # 往话题编辑器里面插入代码模版
  appendCodesFromHint : (language='') ->
    txtBox = $(".slide_editor")
    caret_pos = txtBox.caret('pos')
    prefix_break = ""
    if txtBox.val().length > 0
      prefix_break = "\n"
    src_merged = "#{prefix_break }```#{language}\n\n```\n"
    source = txtBox.val()
    before_text = source.slice(0, caret_pos)
    txtBox.val(before_text + src_merged + source.slice(caret_pos+1, source.count))
    txtBox.caret('pos',caret_pos + src_merged.length - 5)
    txtBox.focus()

  init : ->
    bodyEl = $("body")
    Dropzone.autoDiscover = false
    Slides.initCloseWarning($("textarea.closewarning"))

    $("textarea").bind "keydown","ctrl+return",(el) ->
      return Slides.submitTextArea(el)

    $("textarea").bind "keydown","Meta+return",(el) ->
      return Slides.submitTextArea(el)

    $("textarea").autogrow()

    Slides.initUploader()

    $("a.at_floor").on 'click', (e) ->
      floor = $(this).data('floor')
      Slides.gotoFloor(floor)

    # also highlight if hash is reply#
    matchResult = window.location.hash.match(/^#reply(\d+)$/)
    if matchResult?
      Slides.highlightReply($("#reply#{matchResult[1]}"))

    $("a.small_reply").on 'click', () ->
      Slides.reply($(this).data("floor"), $(this).attr("data-login"))

    Slides.hookPreview($(".editor_toolbar"), $(".slide_editor"))

    # pick up one lang and insert it into the textarea
    $("a.insert_code").on "click", ->
      # not sure IE supports data or not
      Slides.appendCodesFromHint($(this).data('content') || $(this).attr('id') )

    bodyEl.bind "keydown", "m", (el) ->
      $('#markdown_help_tip_modal').modal
        keyboard : true
        backdrop : true
        show : true

    # @ Reply
    logins = App.scanLogins($("#slide_show .leader a[data-author]"))
    $.extend logins, App.scanLogins($('#replies span.name a'))
    logins = ({login: k, name: v, search: "#{k} #{v}"} for k, v of logins)
    App.atReplyable("textarea", logins)

    # Focus title field in new-slide page
    $("body.slides-controller.new-action #slide_title").focus()

$(document).ready ->
  if $('body').data('controller-name') in ['slides', 'replies']
    Slides.init()
